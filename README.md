# Realself::Stream [![CircleCI](https://circleci.com/gh/RealSelf/stream-ruby.svg?style=shield&circle-token=12e8289117eb5dd18737d252efce759a6a8d1afb)](https://circleci.com/gh/RealSelf/stream-ruby/tree/master)

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'realself-stream', '~> 2.0.0', realself: 'stream-ruby'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install realself-stream

## Usage

#### Running Tests
The preferred method for running tests is via `rake` tasks.

```bash
# run all integration and unit tests
$ bundle exec rake test

# run integration tests only
$ bundle exec rake test:integration

# run unit tests only
$ bundle exec rake test:unit

# skip TTL test, while running all others
$ SKIP_TTL_TESTS=true bundle exec rake test
```

* Integration tests assume MongoDB ``~>2.6.0` is running locally and listening on port `27017`.  
* `bundle exec rspec` will run all integration and unit tests
* The TTL integration test must allow the TTL to expire to compleate all tests.  To skip waiiting for the timeout, set the `SKIP_TTL_TESTS` environment variable to `true`.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
