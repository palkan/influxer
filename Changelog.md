# Change log

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