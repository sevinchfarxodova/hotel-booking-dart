# Capacity & Performance Notes

- Peak search target (S1): 200 guests searching within 1 minute, `p95 <= 1s`.
- Energy target (S6): >= 20% reduction per 1,000 searches via cache-aside in Redis.
- Measured results (see `docs/cache-experiment.md`):
  - Without cache: 2,000 DB queries per 1,000 searches (2 queries/search for 2 rooms).
  - With Redis cache-aside (30s TTL): 2 DB queries per 1,000 searches (99.9% hit rate on repeated window).
