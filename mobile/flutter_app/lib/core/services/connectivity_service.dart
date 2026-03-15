import 'dart:async';
import 'dart:io';

/// Simple connectivity detection that does not require the connectivity_plus
/// package (not present in pubspec.yaml). It periodically attempts a DNS/TCP
/// lookup to determine online status and exposes the result as a broadcast
/// stream.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  bool _currentlyOnline = true;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  Timer? _timer;

  /// Stream that emits `true` when online, `false` when offline.
  Stream<bool> get isOnline => _controller.stream;

  /// Synchronous snapshot of the last known connectivity state.
  bool get currentlyOnline => _currentlyOnline;

  /// Call once (e.g. in `main`) to start periodic polling.
  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    _timer?.cancel();
    // Check immediately, then on each interval.
    _check();
    _timer = Timer.periodic(interval, (_) => _check());
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  Future<void> _check() async {
    final online = await _isReachable();
    if (online != _currentlyOnline) {
      _currentlyOnline = online;
      if (!_controller.isClosed) {
        _controller.add(_currentlyOnline);
      }
    }
  }

  /// Tries to open a socket to a well-known host (Cloudflare DNS).
  /// Returns true if successful, false on any network error.
  Future<bool> _isReachable() async {
    try {
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// One-off manual check. Useful on app resume.
  Future<bool> checkNow() async {
    await _check();
    return _currentlyOnline;
  }
}
