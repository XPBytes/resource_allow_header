# Resource Allow Header

[![Build Status: master](https://travis-ci.com/XPBytes/resource_allow_header.svg)](https://travis-ci.com/XPBytes/resource_allow_header) 
[![Gem Version](https://badge.fury.io/rb/resource_allow_header.svg)](https://badge.fury.io/rb/resource_allow_header)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

CanCan supported Allow Header for Rack responses

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'resource_allow_header'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resource_allow_header

## Usage

In your controller use the `allow` class method to determine the value of the `Allow` header:
```ruby
require 'resource_allow_header'

class BookController < ApiController
  allow('HEAD', only: %i[show]) { @book }
  allow('GET', only: %i[show]) { @book }
  allow('POST', only: %i[create]) { Current.author.books.build }
end
```

The allow method expects:
- `http_method`: One of `HEAD`, `GET`, `POST`, `PUT`, `PATCH`, `DELETE`.
- `ability_action` (optional): Automatically mapped from HTTP method and passed to `can?`
- `**options`: passed to `before_action` (so only set these values on show: `only: :show`)
- `&block`: the block that resolved the resource

If no block has been given, the `@allow_resource` instance variable is used, or the `@resource` variable.

The allow header is set as `after_action` callback, which allows your entire request to determine or set the
values you'll be returning in the `&block` passed to `allow`. In other words: these blocks are lazy and
executed in the context of your controller _instance_.

### Configuration

In an initializer you can set procs in order to change the default behaviour:

```ruby
ResourceAllowHeader.configure do |this|
  this.implicit_resource_proc = proc { |controller| controller.resource }
  this.can_proc = proc { |action, resource, controller| action == :whatever || controller.can?(action, resource) }
end
```

## Related

- [`AuthorizedTransaction`](https://github.com/XPBytes/authorized_transaction): :closed_lock_with_key: Authorize an activerecord transaction (or any other transaction) with cancan(can) or any other authorization framework

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [XPBytes/resource_allow_header](https://github.com/XPBytes/resource_allow_header).
