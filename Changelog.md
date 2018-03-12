# Change log

## Misc 
- Support of year alias in queries

## master

- [Fixes [#40](https://github.com/palkan/influxer/issues/40)] Avoid adding precision suffix to write queries. ([@palkan][])

## 1.1.5

- [Fixes [#37](https://github.com/palkan/influxer/issues/37)] Timestamp ranges are quoted again. ([@jklimke][])

## 1.1.4

- [Fixes [#35](https://github.com/palkan/influxer/issues/35)] Support time duration suffix and handle `'s'` and `'ms'` precisions. ([@palkan][])

  [PR](https://github.com/palkan/influxer/pull/36)

  **BREAKING:** `Time`-like value are only typecasted for `time` key.

## 1.1.2

- Support exclusive ranges as `where` arguments. ([@MPursche][])

```ruby
# range including the end
where(a: 1..4)
#=> ... WHERE a >= 1 AND a <= 4

#range excluding the end
where(a: 1...4)
#=> ... WHERE a >= 1 AND a < 4
```

## 1.1.1

- [Fixes [#31](https://github.com/palkan/influxer/issues/31)] Fix bug with empty arrays in `where` clause

- Introduce `Relation#none` method

## 1.1.0

### Features

- Add ability to specify per-metrics retention-policy, precision and database

Now you can override default configuration for a specific metrics class:

```ruby
class CustomMetrics < Influxer::Metrics
  set_database "custom_db"
  set_retention_policy :yearly
  set_precision "ms"
end
```

### Fixes

- [Fixes [#30](https://github.com/palkan/influxer/issues/30)] Fix writing points with custom retention policy

### Misc

- Update Rubocop configuration and add Rubocop Rake task to defaults

## 1.0.1

- Fix missing `#delegate` in ActiveRecord 3.2

## 0.5.4
- Add `set_retention_policy` method

## 0.5.3
- Fix `where.not` with ranges typo

## 0.5.2
- Fix bug with query logging

## 0.5.1
- Fix whitespace around operators
- Add `Relation#from` method to redefine series
- Handle nil values for tags in #where clause

## 0.5.0
- Update `timestamp` support
- Add `epoch` method

## 0.4.0
- Rename default `time` attribute to `timestamp`

## 0.2.3
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

[@palkan]: https://github.com/palkan
[@MPursche]: https://github.com/MPursche
[@jklimke]: https://github.com/jklimke
