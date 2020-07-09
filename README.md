![Build](https://github.com/palkan/influxer/workflows/Build/badge.svg)

# Influxer

Influxer provides an ActiveRecord-style way to work with [InfluxDB](https://influxdb.com/) with many useful features, such as:

## Installation

Adding to a gem:

```ruby
# my-cool-gem.gemspec
Gem::Specification.new do |spec|
  # ...
  spec.add_dependency "influxer", ">= 1.2.0"
  # ...
end
```

Or adding to your project:

```ruby
# Gemfile
gem "influxer", "~> 1.2"
```

## Usage

### Metrics classes

To query InfluxDB or write to it, you should define a metrics class first. Each metrics class represents a measurement/series (or multiple related measurements):

```ruby
class VisitsMetrics < Influxer::Metrics
  # Define tags...
  tags :account_id, :page_id
  # ...and attributes
  attributes :user_id, :browser
end
```

### Querying

Now you can use your metrics classes in a similar way to Active Record models to build queries. For example:

```ruby
VisitsMetrics.select(:account_id, :user_id).where(page_id: /^home\/.*/)
```

Influxer provides special query methods for dealing with time series:

- Group by time: `Metrics.time(:hour) => # select * ... group by time(1h)`.
- Select only points for the last hour/minute/whatever: `Metrics.past(:day) => # select * ... where time > now() - 1d`.
- Select only points since the specified time: `Metrics.since(Time.utc(2014,12,31)) => # select * ... where time > 1419984000s`.
- and more.

See [our Wiki](https://github.com/palkan/influxer/wiki/Query-methods) for more.

### Scopes support

You can define scopes to re-use query conditions:

```ruby
class Metrics < Influxer::Metrics
  tags :account_id
  attributes :value

  default_scope -> { time(:hour).limit(1000) }

  scope :unlimited, -> { limit(nil) }
  scope :by_account, ->(id) { where(account_id: id) if id.present? }
end

Metrics.by_account(1)
# => select * from "metrics" group by time(1h) where account_id=1 limit 1000

Metrics.unlimited.by_account(1).time(:week)
# => select * from "metrics" group by time(1w) where account_id=1
```

### Active Record integration

You can association metrics with Active Record models:

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

Find more on [Wiki](https://github.com/palkan/influxer/wiki/ActiveRecord-integration).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/palkan/influxer](https://github.com/palkan/influxer).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
