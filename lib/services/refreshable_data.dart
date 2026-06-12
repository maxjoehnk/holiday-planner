import 'dart:async';

/// A self-managed fetch-and-refresh pipeline backing a `StreamBuilder`.
///
/// Bundles the per-view boilerplate (controller, change-event subscriptions,
/// async fetch with error handling) into one object. Call `refresh()` to
/// re-fetch on demand; events on any [Stream] passed to `refreshOn` also
/// trigger a fetch. Dispose in the owning `State.dispose()`.
class RefreshableData<T> {
  final Future<T> Function() _fetch;
  final List<StreamSubscription<void>> _subscriptions = [];
  final StreamController<T> _controller = StreamController<T>();
  bool _disposed = false;

  RefreshableData({
    required Future<T> Function() fetch,
    Iterable<Stream<void>> refreshOn = const [],
  }) : _fetch = fetch {
    for (final s in refreshOn) {
      _subscriptions.add(s.listen((_) => refresh()));
    }
    refresh();
  }

  Stream<T> get stream => _controller.stream;

  Future<void> refresh() async {
    if (_disposed || _controller.isClosed) {
      return;
    }
    try {
      final value = await _fetch();
      if (_disposed || _controller.isClosed) {
        return;
      }
      _controller.add(value);
    } catch (e, st) {
      if (_disposed || _controller.isClosed) {
        return;
      }
      _controller.addError(e, st);
    }
  }

  void dispose() {
    _disposed = true;
    for (final s in _subscriptions) {
      s.cancel();
    }
    _controller.close();
  }
}
