# Quickblox API for Ruby

This is a gem to work with [Quickblox API](http://quickblox.com/developers/Overview) in Ruby.

## Use

It all starts by creating a `Quickblox::API` instance with your credentials.

```ruby
require "quickblox"

qb_api = Quickblox::API.new(
  auth_key: "AUTH_KEY",
  auth_secret: "AUTH_SECRET",
  application_id: 1234,
  email: "account@owner.com",
  password: "foobarbaz"
)
```

This will create a user-level token associated to the account with `email` and `password`.

If you don't provide `email` nor `password`, it'll create an application level token.

You don't need to worry about the token itself when using `quickblox-rb`, but it's important to keep in mind that the actions you can make with the API are associated with the token's access right. More about this [here](http://quickblox.com/developers/Authentication_and_Authorization#Access_Rights).

Now you can query the API.

```ruby
qb_api.create_session
# All the methods below use `create_session` if they have to. No need to call it explicitly.

qb_api.get_user(id: 1234)

qb_api.get_dialog(id: "dialog-id")

qb_api.get_messages(dialog_id: "dialog-id")

qb_api.chat_transcript(dialog_id: "dialog-id")
```

These methods return instances of `Quickblox::Models`. I encourage you to [read the source](https://github.com/properati/quickblox-rb/blob/master/lib/models.rb) [and tests](https://github.com/properati/quickblox-rb/blob/master/test/quickblox_api_test.rb) to find more about them.

### Other nice things

Use `Quickblox::API#last_response` to inspect the HTTP response of your latest request. Useful for debugging!

```ruby
qb_api.get_user(id: 123)

qb_api.last_response
```

Inspect your current session:

```ruby
qb_api.create_session

qb_api.session
```

## Install

```
$ gem install quickblox-rb
```

## Development

1. Install [dep](https://github.com/cyx/dep) with `gem install dep`.
2. Run `dep install` to install dependencies.
3. Run the tests with `make`

