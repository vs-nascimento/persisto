import '../utils/network_checker.dart';

class SyncOperation {
  final String path;
  final String method;
  final Map<String, dynamic> body;
  SyncOperation(this.path, this.method, this.body);
}

class SyncManager {
  final List<SyncOperation> _queue = [];

  void enqueue(SyncOperation op) => _queue.add(op);

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

