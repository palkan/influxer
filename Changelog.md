## 0.2.0
- Relation scopes
- Support for fanout series

## 0.1.0
- Add `time` method to Relation to group by time with constants (`:hour`, `:day`, etc) and fill support
- Series names now properly quoted with double-quotes
- [TODO] Using regexp within `where` clause
- [TODO] `where.not(...)` support
- [TODO] Support for `where(id: [...])` (for now arrays are exploding to `where ((...) or (...) or ...)`)