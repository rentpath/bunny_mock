require "bunny_mock/version"

module BunnyMock
  extend self

  def new(*args)
    Bunny.new(*args)
  end

  class Bunny

    def start
      :connected
    end

    def qos
      :qos_ok
    end

    def stop
      nil
    end

    def close
      nil
    end

    def initialize(*args)
    end

    # In the real Bunny gem, this method lives in Bunny::Session
    def create_channel
      BunnyMock::Channel.new
    end

    def direct(name, *args)
      BunnyMock::Exchange.new(name, *args)
    end

    def queue(*args)
      BunnyMock::Queue.new(*args)
    end

    def exchange(name, type, opts = {})
      BunnyMock::Exchange.new(create_channel, type, name, opts)
    end

    def queue(name, opts = {})
      BunnyMock::Queue.new(create_channel, name, opts)
    end

  end # class Bunny

  class Channel
    attr_accessor :exchanges, :queues

    def initialize(*args)
      @exchanges = {}
      @queues = {}
    end

    # Declares a direct exchange or looks it up in the cache of previously
    # declared exchanges.
    def direct(name, opts)
      direct = exchanges[name]
      return direct if direct
      direct = BunnyMock::Exchange.new(self, :direct, name)
      add_exchange(name, direct)
    end

    # Declares a fanout exchange or looks it up in the cache of previously
    # declared exchanges.
    def fanout(name, opts = {})
      fanout = exchanges[name]
      return fanout if fanout
      add_exchange(name, BunnyMock::Exchange.new(self, :fanout, name, opts))
    end

    # Declares a topic exchange or looks it up in the cache of previously
    # declared exchanges.
    def topic(name, opts = {})
      topic = exchanges[name]
      return topic if topic
      add_exchange(name, BunnyMock::Exchange.new(self, :topic, name, opts))
    end

    # Declares a queue or looks it up in the per-channel cache.
    def queue(name = '', opts = {})
      queue = queues[name]
      return queue if queue
      add_queue(name, BunnyMock::Queue.new(self, name, opts))
    end

    private

    def add_exchange(name, exchange)
      @exchanges[name] = exchange
    end

    def add_queue(name, queue)
      @queues[name] = queue
    end
  end

  class Consumer
    attr_accessor :message_count
    def initialize(c)
      self.message_count = c
    end
  end

  class Queue
    attr_accessor :channel, :name, :options, :messages, :delivery_count

    def initialize(channel, name, opts = {})
      self.channel        = channel
      self.name           = name
      self.options        = opts.dup
      self.messages       = []
      self.delivery_count = 0
    end

    def bind(exchange, *args)
      exchange.queues << self
    end

    # Note that this doesn't block waiting for messages like the real world.
    def subscribe(*args, &block)
      while message = messages.shift
        self.delivery_count += 1
        yield({:payload => message})
      end
    end

    def default_consumer
      BunnyMock::Consumer.new(self.delivery_count)
    end

    # NOTE: This is NOT a method that is supported on real Bunny queues.
    #       This is a custom method to get us a deep copy of
    #       all the messages currently in the queue. This is provided
    #       to aid in testing a system where it is not practical for the
    #       test to subscribe to the queue and read the messages, but we
    #       need to verify that certain messages have been published.
    def snapshot_messages
      Marshal.load(Marshal.dump(messages))
    end

    def method_missing(method, *args)
      method_name  = method.to_s
      is_predicate = false
      if method_name =~ /^(.*)\?$/
        key           = $1.to_sym
        is_predicate = true
      else
        key = method.to_sym
      end

      if options.has_key? key
        value = options[key]
        is_predicate ? !!value : value
      else
        super
      end
    end
  end # class Queue

  class Exchange
    attr_accessor :channel, :type, :name, :options, :queues

    def initialize(channel, type, name, opts = {})
      self.channel = channel
      self.type    = type
      self.name    = name
      self.options = opts.dup
      self.queues  = []
    end

    def publish(msg, msg_attrs = {})
      queues.each { |q| q.messages << msg }
    end

    def bound_to?(queue_name)
      queues.any?{|q| q.name == queue_name}
    end

    def method_missing(method, *args)
      method_name  = method.to_s
      is_predicate = false
      if method_name =~ /^(.+)\?$/
        key           = $1.to_sym
        is_predicate = true
      else
        key = method.to_sym
      end

      if options.has_key? key
        value = options[key]
        is_predicate ? !!value : value
      else
        super
      end
    end
  end # class Exchange
end
