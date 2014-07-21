# MessageCenter

MessageCenter provides a Rails Engine for a messaging system that can be used for user-to-user Conversations as well as system notifications.

MessageCenter is based on the wonderful Mailboxer gem and uses a similar database structure and concepts with a few variations.

 * Conversations support messages between users
 * Mailboxes support organizing Conversations between `inbox`, `sentbox` and `trash`
 * Notifications can be sent to one, many, or all users

MessageCenter differs from Mailboxer in a few areas:

 * Multi-user conversations have limited support
 * The object model has been rearchitected using Concerns for easier overriding
 * Messages and Notifications inherit from a base Items class rather than Messages < Notifications
 * Database usage is optimized for PostgreSQL to provide high-performance queries
 * Message and Notification creation is separated from delivery and from email sending (to enable large group sends)

## Installation

Add to your Gemfile:

```ruby
gem 'message_center'
```

Then run:

```sh
$ bundle install
```

Run install script:

```sh
$ rails g message_center:install
```

And don't forget to migrate your database:

```sh
$ rake db:migrate
```

## Usage

In your model:

```ruby
class User < ActiveRecord::Base
  acts_as_messageable
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
