# Resource Allow Header

[![Build Status: master](https://travis-ci.com/XPBytes/resource_allow_header.svg)](https://travis-ci.com/XPBytes/resource_allow_header) 
[![Gem Version](https://badge.fury.io/rb/resource_allow_header.svg)](https://badge.fury.io/rb/resource_allow_header)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

Allow Header for Rack responses using CanCan(Can) or any other authorization framework

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'resource_allow_header'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resource_allow_header
    
This relies on `before_action` and `after_action` to exist, which is normally the case for any controller using 
`AbstractController` in their chain. `Metal` controllers might need to include `Metal::Callbacks`. 

## Usage

In your controller use the `allow` class method to determine the value of the `Allow` header:
```ruby
require 'resource_allow_header'

class ApiController < ActionController::API
  include ResourceAllowHeader
end

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

### Sane defaults

If your API is conforming to REST, you'll usually have the following:

```ruby
allow('HEAD') { @your_resource }
allow('GET') { @your_resource }
allow('POST', only: %i[create index]) { YourResource.new(authorized_context) }
allow('PUT', only: %i[show update]) { @your_resource }
allow('DESTROY', only: %i[show update]) { @your_resource }
```

This is the case because:
- Your `index` path (collection) is the same as your `create` path
- Your `show` path (resource) is the same as your `update` and `delete` path
- You can call `HEAD` both on the collection (`index`) and resource (`show`)
- You can call `GET` on both the collection (`index`) and resource (`show`)
- You can call `POST` only on the collection (`index`) path
- You can call `PUT` and `DESTROY` only on the resource (`show`) path

If 

### Configuration

In an initializer you can set procs in order to change the default behaviour:

```ruby
ResourceAllowHeader.configure do
  self.implicit_resource_proc = proc { |controller| controller.resource }
  self.can_proc = proc { |action, resource, controller| action == :whatever || controller.can?(action, resource) }
end
```

## Related

- [`AuthorizedTransaction`](https://github.com/XPBytes/authorized_transaction): :closed_lock_with_key: Authorize an
  activerecord transaction (or any other transaction) with cancan(can) or any other authorization framework

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [XPBytes/resource_allow_header](https://github.com/XPBytes/resource_allow_header).
