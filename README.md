[![Build Status](https://travis-ci.org/palkan/influxer.svg?branch=master)](https://travis-ci.org/palkan/influxer)

## Influxer

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
        scope :unlimited, -> { limit(nil) }
        scope :by_account, -> (id) { where(account_id: id) if id.present? }
    end

    Metrics.by_account(1)
    # => select * from "metrics" group by time(1h) where account_id=1 limit 1000

    Metrics.unlimited.by_account(1).time(:week)
    # => select * from "metrics" group by time(1w) where account_id=1

    ```
- Support for handling fanout series as one metrics.
    ```ruby
    class Metrics < Influxer::Metrics
        fanout :account, :user, :page
    end

    Metrics.where(account: 1)
    # => select * from "metrics_account_1" 


    Metrics.where(page: 'home').where(user: 12)
    # => select * from "metrics_user_12_page_home" 

    Metrics.where(page: /(home|faq)/).where(account: 1).where(user: 12)
    # => select * from /^metrics_account_1_user_12_page_(home|faq)$/ 

    ``` 
- Integrate with your model:
    ```ruby
    class UserVisits < Influxer::Metrics
    end
    
    class User < ActiveRecord::Base
        has_metrics :visits
    end

    user = User.find(1)
    user.visits.write(page_id: 'home')
    #=> < creates point {user_id: 1, page_id: 'home'} in 'user_visits' series >

    user.visits.where(page_id: 'home')
    #=> select * from user_visits where page_id='home'
    ```
    
Find more on [Wiki](/palkan/influxer/wiki).
