import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:holiday_planner/src/rust/api/sync.dart' as rust_sync;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Owns the Supabase auth session on the Dart side. The Rust core never talks
/// to GoTrue directly — Dart signs in / refreshes via `supabase_flutter` and
/// pushes every resulting JWT into Rust via [rust_sync.setAuthSession].
///
/// Login is optional: when no session is present, the app runs anonymously
/// against local SQLite, exactly as before.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();
  User? _currentUser;
  bool _started = false;
  _DesktopSignInSession? _desktopSession;

  /// Hook up to `supabase_flutter` and replay the existing session, if any,
  /// into Rust. Idempotent.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    final client = Supabase.instance.client;
    _currentUser = client.auth.currentUser;
    _userController.add(_currentUser);
    await _forwardSession(client.auth.currentSession);

    client.auth.onAuthStateChange.listen(
      (state) async {
        _currentUser = state.session?.user;
        _userController.add(_currentUser);
        await _forwardSession(state.session);
      },
      onError: (Object error, StackTrace stack) {
        log('AuthService upstream error: $error', stackTrace: stack);
      },
      cancelOnError: false,
    );
  }

  Future<void> _forwardSession(Session? session) async {
    try {
      if (session == null) {
        await rust_sync.setAuthSession();
        return;
      }
      await rust_sync.setAuthSession(
        session: rust_sync.AuthSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken ?? '',
          userId: session.user.id,
          expiresAtUnixSeconds: PlatformInt64Util.from(session.expiresAt ?? 0),
        ),
      );
    } catch (error, stack) {
      log('AuthService.forwardSession failed: $error', stackTrace: stack);
    }
  }

  User? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  Stream<User?> get changes => _userController.stream;

  /// Send a magic-link to the given email.
  ///
  /// Mobile (and any platform with a registered URL scheme): the email link
  /// opens the app via deep link and `supabase_flutter` finishes the
  /// session itself.
  ///
  /// Desktop (macOS / Linux / Windows): deep link handling is unreliable, so
  /// we spin up a loopback HTTP listener on `http://127.0.0.1:<port>` and use
  /// that as the redirect target. The OS opens the user's browser, the
  /// browser hits our loopback URL, and we exchange the PKCE code for a
  /// session. `http://127.0.0.1:*/auth/callback` must be present in the
  /// Supabase project's "Allowed redirect URLs" list.
  Future<void> sendMagicLink({required String email}) async {
    if (_isDesktop) {
      return _startDesktopSignIn(email);
    }
    return Supabase.instance.client.auth.signInWithOtp(email: email);
  }

  Future<void> signOut() => Supabase.instance.client.auth.signOut();

  /// Cancel an in-flight desktop sign-in (e.g. when the user closes the
  /// sign-in screen before clicking the email link).
  Future<void> cancelPendingSignIn() async {
    await _desktopSession?.cancel();
    _desktopSession = null;
  }

  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  Future<void> _startDesktopSignIn(String email) async {
    // Make sure any earlier attempt is torn down before we start a new one.
    await cancelPendingSignIn();

    final session = await _DesktopSignInSession.start();
    _desktopSession = session;

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: session.redirectUri,
      );
    } catch (e) {
      await session.cancel();
      _desktopSession = null;
      rethrow;
    }

    // Run the completion in the background so the caller's future resolves
    // as soon as the email is sent; the UI watches AuthService.changes to
    // know when the click-through actually completes.
    unawaited(session.completion.then(
      (uri) async {
        try {
          await Supabase.instance.client.auth.getSessionFromUrl(uri);
        } catch (error, stack) {
          log('Desktop sign-in completion failed: $error', stackTrace: stack);
        } finally {
          if (identical(_desktopSession, session)) {
            _desktopSession = null;
          }
          await session.dispose();
        }
      },
      onError: (Object error, StackTrace stack) async {
        log('Desktop sign-in listener failed: $error', stackTrace: stack);
        if (identical(_desktopSession, session)) {
          _desktopSession = null;
        }
        await session.dispose();
      },
    ));
  }
}

/// Loopback listener for desktop magic-link callbacks. One instance per
/// in-flight sign-in attempt.
class _DesktopSignInSession {
  _DesktopSignInSession._(this._server, this._completer);

  final HttpServer _server;
  final Completer<Uri> _completer;
  late final StreamSubscription<HttpRequest> _sub;
  Timer? _timeout;

  static const Duration _ttl = Duration(minutes: 15);

  static Future<_DesktopSignInSession> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final completer = Completer<Uri>();
    final s = _DesktopSignInSession._(server, completer);
    s._sub = server.listen(s._handle, onError: (Object e, StackTrace st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    });
    s._timeout = Timer(_ttl, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Magic link not clicked within ${_ttl.inMinutes} minutes.'),
        );
      }
    });
    return s;
  }

  String get redirectUri => 'http://127.0.0.1:${_server.port}/auth/callback';

  Future<Uri> get completion => _completer.future;

  Future<void> _handle(HttpRequest req) async {
    try {
      if (req.uri.path == '/auth/callback') {
        if (!_completer.isCompleted) {
          // The Uri delivered by HttpRequest has no scheme/host — synthesise
          // a full one so Supabase's URL parser is happy.
          final fullUri = Uri.parse('$redirectUri?${req.uri.query}');
          _completer.complete(fullUri);
        }
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(_successPage);
      } else {
        req.response.statusCode = HttpStatus.notFound;
      }
    } finally {
      await req.response.close();
    }
  }

  /// Called by the UI if the user backs out before the link is clicked.
  Future<void> cancel() async {
    if (!_completer.isCompleted) {
      _completer.completeError(
        const _SignInCancelled('Sign-in cancelled by the user.'),
      );
    }
    await dispose();
  }

  Future<void> dispose() async {
    _timeout?.cancel();
    _timeout = null;
    await _sub.cancel();
    await _server.close(force: true);
  }
}

class _SignInCancelled implements Exception {
  const _SignInCancelled(this.message);
  final String message;
  @override
  String toString() => 'SignInCancelled: $message';
}

const String _successPage = '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Signed in</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
           background: #fafafa; color: #222; margin: 0;
           display: flex; align-items: center; justify-content: center; height: 100vh; }
    .card { background: white; padding: 2.5rem 3rem; border-radius: 12px;
            box-shadow: 0 1px 6px rgba(0,0,0,.08); text-align: center; max-width: 26rem; }
    h1 { margin: 0 0 .5rem; font-size: 1.4rem; }
    p  { margin: 0; color: #555; }
  </style>
</head>
<body>
  <div class="card">
    <h1>You're signed in</h1>
    <p>You can close this window and return to Trippy.</p>
  </div>
</body>
</html>
''';
