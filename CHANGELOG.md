# Change log

## master (unreleased)

- added support for providing hash objects as arguments to where condition in ruby >= 3

## 1.4.0 (2022-01-24)

- Fixes [#55](https://github.com/palkan/influxer/issues/55) Rails 7 deprecation warning
- Add Ruby3 Support
- Updates InfluxDB client dependency
- Removes Ruby 2.4 supporting

## 1.3.0 (2020-10-27)

- Fixes [#53](https://github.com/palkan/influxer/issues/53) Influxer client configuration issue with anyway config v2 and higher.([@AlexanderShvaykin][])

## 1.2.2 (2020-10-27)

- Fixes [#49](https://github.com/palkan/influxer/issues/49) Cache hash configuration cannot be applied.([@AlexanderShvaykin][])
- Fixes [#47](https://github.com/palkan/influxer/issues/47) Can't delete data when retention policy is set for a metric. ([@MPursche][])

## 1.2.1 (2020-07-09)

- Support for setting timezone in queries to configure influx time calculations, e.g., time epoch aggregation ([@jklimke][])

  [PR](https://github.com/palkan/influxer/pull/46)

## 1.2.0 (2019-05-20)

- **Require Ruby 2.4+**

## 1.1.6

- [Fixes [#41](https://github.com/palkan/influxer/issues/41)] Fix query building with empty arrays in `where` clause ([@dimiii][])

  [PR](https://github.com/palkan/influxer/pull/44)

  **BREAKING:** `where.not` now returns non-empty result for an empty array.

- Support of year alias in queries ([@dimiii][])

- [Fixes [#40](https://github.com/palkan/influxer/issues/40)] Avoid adding precision suffix to write queries. ([@palkan][])

## 1.1.5

- [Fixes [#37](https://github.com/palkan/influxer/issues/37)] Timestamp ranges are quoted again. ([@jklimke][])

## 1.1.4

- [Fixes [#35](https://github.com/palkan/influxer/issues/35)] Support time duration suffix and handle `'s'` and `'ms'` precision. ([@palkan][])

  [PR](https://github.com/palkan/influxer/pull/36)

  **BREAKING:** `Time`-like value are only type-casted for `time` key.

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

See [changelog](https://github.com/palkan/influxer/blob/1.0.0/Changelog.md) for earlier versions.

[@palkan]: https://github.com/palkan
[@mpursche]: https://github.com/MPursche
[@jklimke]: https://github.com/jklimke
[@dimiii]: https://github.com/dimiii
[@alexandershvaykin]: https://github.com/AlexanderShvaykin
