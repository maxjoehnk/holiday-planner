import 'dart:async';
import 'dart:developer';

import 'package:holiday_planner/src/rust/api/sync.dart';

/// Singleton bridge mirroring [DataChangeBus] but for the [SyncStatus]
/// stream coming from `crate::sync::status`. Widgets that show a sync
/// banner / indicator listen here.
class SyncStatusBus {
  SyncStatusBus._();
  static final SyncStatusBus instance = SyncStatusBus._();

  final StreamController<SyncStatus> _controller =
      StreamController<SyncStatus>.broadcast();
  StreamSubscription<SyncStatus>? _upstream;
  SyncStatus? _last;

  void start() {
    if (_upstream != null) {
      return;
    }
    _connect();
  }

  void _connect() {
    _upstream = syncStatusStream().listen(
      (event) {
        _last = event;
        _controller.add(event);
      },
      onError: (Object error, StackTrace stack) {
        log('SyncStatusBus upstream error: $error', stackTrace: stack);
      },
      onDone: () {
        _upstream = null;
        _connect();
      },
      cancelOnError: false,
    );
  }

  Stream<SyncStatus> get changes => _controller.stream;
  SyncStatus? get last => _last;
}
