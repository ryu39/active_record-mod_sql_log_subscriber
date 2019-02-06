# ActiveRecord::ModSqlLogSubscriber

An ActiveRecord::LogSubscriber which records only mod-SQL logs.

The mod-SQL is shown as follows.

* INSERT
* UPDATE
* DELETE
* TRUNCATE
* BEGIN
* COMMIT
* ROLLBACK
* SAVEPOINT
* RELEASE SAVEPOINT
* ROLLBACK TO SAVEPOINT

## Motivation

* SQL logs are useful for trouble shooging.
* Especialy, mod-SQL(INSERT, UPDATE, DELETE, ...) logs are very important to know what occurred in app.
* Rails provides SQL logging feature only by settings `Rails.logger` log level to `:debug`.
* But this settings writes a lot of `SELECT` statement SQL logs.
  These logs are very noisy and use many disk space.
* I want to write logs only mod-SQL(INSERT, UPDATE, DELETE, ...) and transaction SQL(BEGIN, COMMIT, ROLLBACK, ...).
  So I create this gem.

## Requirements

* Rails >= 5.1.5

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record-mod_sql_log_subscriber'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install active_record-mod_sql_log_subscriber

## Usage

Create a file under`config/initializer`, configure log subscriber, 
and attach to :active_record namespace.

```
require 'active_record/mod_sql_log_subscriber'

::ActiveRecord::ModSqlLogSubscriber.configure do |config|
  config.disable = ::ActiveRecord::Base.logger.debug? # Recommended
end

::ActiveRecord::ModSqlLogSubscriber.attach_to(:active_record)
```

Next restart your app, then your app starts to log mod-SQLs.

Here is rails console examples.

```
$ rails c

> ActiveRecord::Base.logger = Logger.new(STDOUT)

> user = User.find(1); nil # Do not logging

> user.update_attributes(name: 'New name'); nil # Do logging
# => "UPDATE users SET name = 'New name' WHERE id = $1  {:id=>1}"
```

### Try console

You can try this gem by cloning this repo and run `bin/setup` and `bin/console`.

```
$ git clone https://github.com/ryu39/active_record-mod_sql_log_subscriber.git
$ cd active_record-mod_sql_log_subscriber

# Run bundle install and create sqlite3 database.
$ bin/setup

# Connect sqlite3 database and start IRB.
$ bin/console

> User.count # => no log

> User.create!(name: 'name', age: 20, birth_date: Date.new(2000, 1, 1))
# => I, [2019-02-05T11:04:07.489057 #42019]  INFO -- : begin transaction
#    I, [2019-02-05T11:04:07.490495 #42019]  INFO -- : INSERT INTO "users" ("name", "age", "birth_date", "created_at", "updated_at") VALUES (?, ?, ?, ?, ?)  [["name", "name"], ["age", 20], ["birth_date", "2000-01-01"], ["created_at", "2019-02-05 02:04:07.489226"], ["updated_at", "2019-02-05 02:04:07.489226"]]
#    I, [2019-02-05T11:04:07.492610 #42019]  INFO -- : commit transaction

> user = User.last # => no log
> user.update_attributes(name: 'new name')
# => I, [2019-02-05T11:04:52.971503 #42019]  INFO -- : begin transaction
#    I, [2019-02-05T11:04:52.973071 #42019]  INFO -- : UPDATE "users" SET "name" = ?, "updated_at" = ? WHERE "users"."id" = ?  [["name", "new name"], ["updated_at", "2019-02-05 02:04:52.971865"], ["id", 2]]
#    I, [2019-02-05T11:04:52.974081 #42019]  INFO -- : commit transaction

> user.destroy
# => I, [2019-02-05T11:05:13.765564 #42019]  INFO -- : begin transaction
#    I, [2019-02-05T11:05:13.775460 #42019]  INFO -- : DELETE FROM "users" WHERE "users"."id" = ?  [["id", 2]]
#    I, [2019-02-05T11:05:13.776722 #42019]  INFO -- : commit transaction
```

## Configuration

You can configure this subscriber before attaching to :active_record namespace

```
::ActiveRecord::ModSqlLogSubscriber.configure do |config|
  config.disable = true
  config.log_level = :warn
  config.log_format = :json
  # config.log_format = ->(sql, binds) { 'your code here' }
  config.target_statements << 'merge'
end

# You must attach subscriber after configuraton.
::ActiveRecord::ModSqlLogSubscriber.attach_to(:active_record)
```

### Enable/Disable

You can make log subscriber enbaled/disabled via config. Default is enabled.
This is useful in development/test env because duplicated sql logs are written in log in this env.

```
::ActiveRecord::ModSqlLogSubscriber.configure do |config|
  config.disable = false # enabled
  config.disable = true # disabled
  
  config.disable = ::ActiveRecord::Base.logger.debug? # Recommended
end
```

### Log level

You can change log level. Default is :info.

```
::ActiveRecord::ModSqlLogSubscriber.configure do |config|
  config.log_level = :warn
  # config.log_level = :error
  # config.log_level = :fatal
end
```

### Log format

You can select log format as follows, or use a custom Proc object.

* `:text` (Default)
* `:json`
* `:hash`
* Proc object

### Target statement

You can add/change/remove target SQL statements.

```
::ActiveRecord::ModSqlLogSubscriber.configure do |config|
  # Add MERGE SQL
  config.target_statements << 'merge' 
  
  # Remove BEGIN SQL
  config.target_stagements.delete('begin')
  
  # Orverwite your target statements
  config.target_statements = %w(insert update delete)
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 
To release a new version, update the version number in `mod_sql_log_subscriber.r`, 
and then run `bundle exec rake release`, which will create a git tag for the version, 
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ryu39/active_record-mod_sql_log_subscriber. 
This project is intended to be a safe, welcoming space for collaboration, 
and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecord::ModSqlLogSubscriber project’s codebases, issue trackers, 
chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ryu39/active_record-mod_sql_log_subscriber/blob/master/CODE_OF_CONDUCT.md).
