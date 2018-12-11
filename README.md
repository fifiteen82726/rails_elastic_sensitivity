## What is Rails Elastic Sensitivity? 

Elastic sensitivity is an approach which was invented by UBER for efficiently approximating the local sensitivity of a query, which can be used to
enforce differential privacy for the query. The approach requires only a static analysis of the query and therefore
imposes minimal performance overhead. Importantly, it does not require any changes to the database.
Details of the approach are available in [this paper](https://arxiv.org/abs/1706.09479).

This Project implement this mechanism on Rails to achieve counting query with any DataBase Rails support (MySQL, PostSQL, SQLite, etc).


## Installation

Add this line to your application's Gemfile:

```ruby
# Lastest Version
gem 'rails_elastic_sensitivity'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rails_elastic_sensitivity

## Usage

Single Join Example:

```rb
# Create Instance
es = ElaticSensitivity.new(:user)

# See true query result
es.joins(:gamecharacters).where(gamecharacters: {course_id: 100}).count

# See query result with elastic sensitivity mechanism
es.joins(:gamecharacters).where(gamecharacters: {course_id: 100}).elastic_count
```

Double Join Example:
```rb
es = ElaticSensitivity.new(:user)
es.joins(gamecharacters: :gc_achievements).where(gamecharacters: {course_id: 1}).count
es.joins(gamecharacters: :gc_achievements).where(gamecharacters: {course_id: 1}).elastic_count
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails_elastic_sensitivity. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RailsElasticSensitivity project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rails_elastic_sensitivity/blob/master/CODE_OF_CONDUCT.md).
