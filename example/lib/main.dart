import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persisto/persisto.dart';

const _pokemonSource = 'pokemon';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final cache = HiveCache();
  await cache.init();

  final httpAdapter = HttpAdapter(
    baseUrl: 'https://pokeapi.co/api/v2',
    headers: const {'Content-Type': 'application/json'},
  );

  final interceptor = OfflineInterceptor(
    cache: cache,
    policies: {
      _pokemonSource: CachePolicy(
        ttl: const Duration(minutes: 5),
        strategy: CacheStrategy.cacheFirst,
      ),
    },
  );

  runApp(
    OfflineDemoApp(
      cache: cache,
      interceptor: interceptor,
      httpAdapter: httpAdapter,
    ),
  );
}

class OfflineDemoApp extends StatelessWidget {
  const OfflineDemoApp({
    super.key,
    required this.cache,
    required this.interceptor,
    required this.httpAdapter,
  });

  final HiveCache cache;
  final OfflineInterceptor interceptor;
  final HttpAdapter httpAdapter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Interceptor Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: DemoHomePage(
        cache: cache,
        interceptor: interceptor,
        httpAdapter: httpAdapter,
      ),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({
    super.key,
    required this.cache,
    required this.interceptor,
    required this.httpAdapter,
  });

  final HiveCache cache;
  final OfflineInterceptor interceptor;
  final HttpAdapter httpAdapter;

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  bool _loading = false;
  List<Map<String, dynamic>> _pokemon = const [];
  String? _error;
  DateTime? _lastUpdated;
  bool _overridePolicy = true;
  CacheStrategy _strategyOverride = CacheStrategy.networkFirst;
  double _ttlSeconds = 120;
  bool _compareWithCache = true;
  bool _refreshCacheOnEquality = true;
  bool? _lastUsedCache;
  String? _comparisonMessage;
  int _limit = 20;
  int _offset = 0;

  Future<void> _loadPokemon() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cacheKey = '/pokemon?limit=$_limit&offset=$_offset';
      final cachedSnapshot =
          await widget.cache.read(cacheKey) as Map<String, dynamic>?;
      final cachedData = cachedSnapshot?['data'];

      final data =
          await widget.interceptor.fetch(
                source: _pokemonSource,
                key: cacheKey,
                request: () async => widget.httpAdapter.get(
                  '/pokemon',
                  params: {
                    'limit': _limit.toString(),
                    'offset': _offset.toString(),
                  },
                ),
                strategyOverride: _overridePolicy ? _strategyOverride : null,
                ttlOverride: _overridePolicy
                    ? Duration(seconds: _ttlSeconds.round())
                    : null,
                compareWithCache: _compareWithCache,
                refreshCacheOnEquality: _refreshCacheOnEquality,
                equalityComparer: _compareWithCache ? _arePokemonEqual : null,
              )
              as Map<String, dynamic>;

      final pokemonList = _extractPokemon(data);
      final hasCache = cachedData != null;
      final matchesCache = hasCache && _arePokemonEqual(cachedData, data);
      final comparisonMessage = _buildComparisonMessage(
        hasCache: hasCache,
        matchesCache: matchesCache,
      );

      setState(() {
        _pokemon = pokemonList;
        _lastUpdated = DateTime.now();
        _lastUsedCache = matchesCache;
        _comparisonMessage = comparisonMessage;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _clearCache() async {
    await widget.cache.clear();
    setState(() {
      _pokemon = const [];
      _lastUpdated = null;
      _lastUsedCache = null;
      _comparisonMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Interceptor + Hive')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pokemon catalog via PokeAPI',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _PolicyOverrideControls(
              overrideEnabled: _overridePolicy,
              strategyOverride: _strategyOverride,
              ttlSeconds: _ttlSeconds,
              onOverrideChanged: (value) =>
                  setState(() => _overridePolicy = value),
              onStrategyChanged: (strategy) =>
                  setState(() => _strategyOverride = strategy),
              onTtlChanged: (value) => setState(() => _ttlSeconds = value),
            ),
            const SizedBox(height: 12),
            _ComparisonControls(
              compareWithCache: _compareWithCache,
              refreshOnEquality: _refreshCacheOnEquality,
              onCompareChanged: (value) =>
                  setState(() => _compareWithCache = value),
              onRefreshChanged: (value) =>
                  setState(() => _refreshCacheOnEquality = value),
            ),
            const SizedBox(height: 12),
            _OffsetControls(
              limit: _limit,
              offset: _offset,
              onLimitChanged: (value) => setState(() => _limit = value),
              onOffsetChanged: (value) => setState(() => _offset = value),
            ),
            const SizedBox(height: 12),
            _OffsetControls(
              limit: _limit,
              offset: _offset,
              onLimitChanged: (value) => setState(() => _limit = value),
              onOffsetChanged: (value) => setState(() => _offset = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _loadPokemon,
                  child: const Text('Fetch Pokemon'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _clearCache,
                  child: const Text('Clear cache'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            if (_comparisonMessage != null)
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _comparisonMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            if (_lastUsedCache != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Last response source: '
                  '${_lastUsedCache! ? 'Cache' : 'Network'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_lastUpdated != null)
              Text(
                'Last updated: ${_lastUpdated!.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _pokemon.isEmpty
                  ? const Center(
                      child: Text(
                        'No Pokemon loaded yet. Tap "Fetch Pokemon".',
                      ),
                    )
                  : ListView.separated(
                      itemCount: _pokemon.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final pokemon = _pokemon[index];
                        final name =
                            (pokemon['name'] as String?)?.toUpperCase() ??
                            'UNKNOWN';
                        final url = pokemon['url'] as String? ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${_offset + index + 1}'),
                          ),
                          title: Text(name),
                          subtitle: Text(url),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildComparisonMessage({
    required bool hasCache,
    required bool matchesCache,
  }) {
    if (!_compareWithCache) {
      if (hasCache && matchesCache) {
        return 'Returned cached Pokemon based on cache-first policy.';
      }
      return 'Fetched Pokemon from network.';
    }

    if (!hasCache) {
      return 'No cached Pokemon available. Stored the fresh network response.';
    }

    if (matchesCache) {
      return _refreshCacheOnEquality
          ? 'Network response matched cache. TTL refreshed, cache returned.'
          : 'Network response matched cache. Cache reused without refresh.';
    }

    return 'Network response differed from cache. Cache updated with new Pokemon.';
  }

  List<Map<String, dynamic>> _extractPokemon(dynamic data) {
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) {
        return results
            .whereType<Map<String, dynamic>>()
            .map(
              (pokemon) => {
                'name': pokemon['name'] ?? 'unknown',
                'url': pokemon['url'] ?? '',
              },
            )
            .toList();
      }
    }
    return const [];
  }

  bool _arePokemonEqual(dynamic cached, dynamic fresh) {
    if (cached == null || fresh == null) return false;

    final cachedList = _extractPokemon(cached);
    final freshList = _extractPokemon(fresh);

    if (cachedList.length != freshList.length) return false;

    const equality = DeepCollectionEquality.unordered();
    return equality.equals(
      cachedList.map((pokemon) => pokemon['name'] as String? ?? '').toList(),
      freshList.map((pokemon) => pokemon['name'] as String? ?? '').toList(),
    );
  }
}

class _OffsetControls extends StatelessWidget {
  const _OffsetControls({
    required this.limit,
    required this.offset,
    required this.onLimitChanged,
    required this.onOffsetChanged,
  });

  final int limit;
  final int offset;
  final ValueChanged<int> onLimitChanged;
  final ValueChanged<int> onOffsetChanged;

  static const _limitOptions = [10, 20, 30, 50];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Limit:'),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: limit,
              onChanged: (value) {
                if (value != null) onLimitChanged(value);
              },
              items: _limitOptions
                  .map(
                    (count) => DropdownMenuItem<int>(
                      value: count,
                      child: Text('$count'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(width: 24),
            Text('Offset: $offset'),
          ],
        ),
        Slider(
          value: offset.toDouble(),
          min: 0,
          max: 200,
          divisions: 20,
          label: '$offset',
          onChanged: (value) => onOffsetChanged(value.round()),
        ),
      ],
    );
  }
}

class _PolicyOverrideControls extends StatelessWidget {
  const _PolicyOverrideControls({
    required this.overrideEnabled,
    required this.strategyOverride,
    required this.ttlSeconds,
    required this.onOverrideChanged,
    required this.onStrategyChanged,
    required this.onTtlChanged,
  });

  final bool overrideEnabled;
  final CacheStrategy strategyOverride;
  final double ttlSeconds;
  final ValueChanged<bool> onOverrideChanged;
  final ValueChanged<CacheStrategy> onStrategyChanged;
  final ValueChanged<double> onTtlChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(value: overrideEnabled, onChanged: onOverrideChanged),
            const SizedBox(width: 8),
            const Text('Override policy per request'),
          ],
        ),
        if (overrideEnabled) ...[
          Row(
            children: [
              const Text('Strategy:'),
              const SizedBox(width: 12),
              DropdownButton<CacheStrategy>(
                value: strategyOverride,
                onChanged: (value) {
                  if (value != null) onStrategyChanged(value);
                },
                items: CacheStrategy.values
                    .map(
                      (strategy) => DropdownMenuItem<CacheStrategy>(
                        value: strategy,
                        child: Text(_strategyLabel(strategy)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'TTL override: ${ttlSeconds.round()} seconds',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(
            value: ttlSeconds,
            min: 10,
            max: 600,
            divisions: 59,
            label: '${ttlSeconds.round()}s',
            onChanged: onTtlChanged,
          ),
        ],
      ],
    );
  }

  static String _strategyLabel(CacheStrategy strategy) {
    switch (strategy) {
      case CacheStrategy.networkFirst:
        return 'Network first';
      case CacheStrategy.cacheFirst:
        return 'Cache first';
      case CacheStrategy.cacheOnly:
        return 'Cache only';
    }
  }
}

class _ComparisonControls extends StatelessWidget {
  const _ComparisonControls({
    required this.compareWithCache,
    required this.refreshOnEquality,
    required this.onCompareChanged,
    required this.onRefreshChanged,
  });

  final bool compareWithCache;
  final bool refreshOnEquality;
  final ValueChanged<bool> onCompareChanged;
  final ValueChanged<bool> onRefreshChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(value: compareWithCache, onChanged: onCompareChanged),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Compare network response with cached data before updating',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (compareWithCache)
          Row(
            children: [
              Switch(value: refreshOnEquality, onChanged: onRefreshChanged),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Refresh TTL when response matches cache',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
