## 0.2.2
- Parse fanout queries points to handle _fanouted_ values
- Add Rubocop config and cleanup code style

## 0.1.1
- Add [anyway_config](https://github.com/palkan/anyway_config)
- Add `empty?` method

## 0.1.0
- Add logs
- Add `foreign_key` param to `has_metrics` options

## 0.1.0-rc
- Fix `Relation#to_a` (now returns array of points correctrly)
- Fix fanout queries with array args (now use `merge(Regexp)`)

## 0.1.0-alpha
- Add `time` method to Relation to group by time with constants (`:hour`, `:day`, etc) and fill support
- Series names now properly quoted with double-quotes
- Using regexps, ranges and arrays within `where` clause
- `where.not(...)` support
- Add `past` and `since` methods
- Add `merge` method and support for regexp series
- Add `delete_all` support
- Add cache support (using `Rails.cache`)
- Scopes (default and named)
- Support for fanout series