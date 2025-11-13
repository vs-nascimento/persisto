import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persisto/persisto.dart';

/// Basic smoke tests to ensure main exports are usable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const connectivityChannel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity',
  );
  connectivityChannel.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'check') {
      return ['wifi'];
    }
    return null;
  });

  test('creates offline interceptor with in-memory cache', () async {
    final interceptor = OfflineInterceptor(
      cache: MemoryCache(),
      policies: {
        'test': CachePolicy(
          ttl: const Duration(seconds: 5),
          strategy: CacheStrategy.cacheFirst,
        ),
      },
    );

    Future<int> remoteCallCounter() async => 42;

    final first = await interceptor.fetch(
      source: 'test',
      key: 'answer',
      request: remoteCallCounter,
    );

    expect(first, 42);

    // Second call should hit cache.
    final second = await interceptor.fetch(
      source: 'test',
      key: 'answer',
      request: () => throw StateError('should not call'),
    );

    expect(second, 42);
  });
}
