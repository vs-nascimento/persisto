# Persisto example

This Flutter example consumes the public [PokeAPI](https://pokeapi.co/) and demonstrates how to use `persisto` with different cache backends and per-request overrides.

Key interactions:

- Switch between Hive, SharedPreferences, and in-memory caches.
- Change the cache strategy and TTL before performing a request.
- Toggle equality comparison to avoid rewriting identical payloads.
- Adjust pagination (`limit` / `offset`) to see cache keys evolve.

Run the demo:

```bash
cd example
flutter run
```
