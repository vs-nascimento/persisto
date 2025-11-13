import '../utils/network_checker.dart';

/// Immutable representation of a pending mutation.
class SyncOperation {
  /// Creates a sync operation targeting [path] with HTTP [method] and [body].
  SyncOperation(this.path, this.method, this.body);

  /// Endpoint path.
  final String path;

  /// HTTP verb (POST, PUT, DELETE, ...).
  final String method;

  /// Request payload.
  final Map<String, dynamic> body;
}

/// Queue responsible for replaying offline mutations when connectivity returns.
class SyncManager {
  final List<SyncOperation> _queue = [];

  /// Adds [op] to the queue.
  void enqueue(SyncOperation op) => _queue.add(op);

  /// Attempts to process every queued operation with the provided [executor].
  Future<void> processQueue(
    Future<void> Function(SyncOperation op) executor,
  ) async {
    final online = await NetworkChecker.isOnline;
    if (!online) return;
    final pending = List.of(_queue);
    for (final op in pending) {
      try {
        await executor(op);
        _queue.remove(op);
      } catch (_) {}
    }
  }
}
