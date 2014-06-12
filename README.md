# BunnyMock

**Version: 0.0.2**

This is a brain-dead-simple mock for the `Bunny` class provided by the [bunny gem](https://github.com/ruby-amqp/bunny), which is a synchronous Ruby RabbitMQ client. If you want to mock out RabbitMQ in your tests and are currently using Bunny, this might be the tool for you.

BunnyMock does not mock all of the methods of Bunny. It currently only mocks the behavior I needed for my immediate needs, which is mainly creating and binding queues and exchanges, and publishing/subscribing messages.

Feel free to fork it to add more behavior mocking and send me a pull request.

## Installation

The easiest way to use this is to drop bunny_mock.rb into your `spec/support` directory, or something like that. Just require bunny_mock and then use `BunnyMock.new` instead of `Bunny.new(params)`.

Add this line to your application's Gemfile:

    gem 'bunny_mock'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bunny_mock

## Usage

Since this is intended as a simple way to help test your collaboration with Bunny/RabbitMQ, it does not really opereate as a real queue, but it _does_ support receiving messages into a queue, and reading them out. The main thing to be aware of is that the `BunnyMock::Queue#subscribe` method does not block waiting for messages, consumes all queued messages, and returns when there are no more messages. This differs from the behavior of the real Bunny.

See the first "integration" test case in `spec/lib/bunny_mock_spec.rb` for a quick example of how to use BunnyMock.

# Author

Scott W. Bradley - http://scottwb.com

## Contributing

1. Fork it ( https://github.com/[my-github-username]/bunny_mock/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

# License

This code is licensed under [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
