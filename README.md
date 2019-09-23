[![Gem Version](https://badge.fury.io/rb/influxer.svg)](https://rubygems.org/gems/influxer) [![Build Status](https://travis-ci.org/palkan/influxer.svg?branch=master)](https://travis-ci.org/palkan/influxer) [![Dependency Status](https://dependencyci.com/github/palkan/influxer/badge)](https://dependencyci.com/github/palkan/influxer)
## Influxer

**NOTE**: Version 0.3.x supports InfluxDB >= 0.9.0. For InfluxDB 0.8.x use [version 0.2.5](https://github.com/palkan/influxer/tree/0.2.5).

**NOTE**: Influxer is Rails 4+ compatible! (Rails 3.2 support is still included but no longer required to pass all the tests).

Influxer provides an ActiveRecord-style way to work with [InfluxDB](https://influxdb.com/) with many useful features, such as:
- Familar query language (use `select`, `where`, `not`, `group` etc).
- Support for Regex conditions: `where(page_id: /^home\/.*/) #=> select * ... where page_id=~/^home\/.*/`.
- Special query methods for InfluxDB:
  - `time` - group by time (e.g. `Metrics.time(:hour) => # select * ... group by time(1h)`);
  - `past` - get only points for last hour/minute/whatever (e.g. `Metrics.past(:day) => # select * ... where time > now() - 1d`);
  - `since` - get only points since date (e.g. `Metrics.since(Time.utc(2014,12,31)) => # select * ... where time > 1419984000s`);
  - `merge` - merge series.
- Scopes support

```ruby
class Metrics < Influxer::Metrics
  default_scope -> { time(:hour).limit(1000) }
  tags :account_id
  attributes :value
  scope :unlimited, -> { limit(nil) }
  scope :by_account, ->(id) { where(account_id: id) if id.present? }
end

Metrics.by_account(1)
# => select * from "metrics" group by time(1h) where account_id=1 limit 1000

Metrics.unlimited.by_account(1).time(:week)
# => select * from "metrics" group by time(1w) where account_id=1
```

- Integrate with your model:

```ruby
class UserVisits < Influxer::Metrics
end

class User < ActiveRecord::Base
  has_metrics :visits
end

user = User.find(1)
user.visits.write(page_id: "home")
#=> < creates point {user_id: 1, page_id: 'home'} in 'user_visits' series >

user.visits.where(page_id: "home")
#=> select * from user_visits where page_id='home'
```

Find more on [Wiki](https://github.com/palkan/influxer/wiki).
