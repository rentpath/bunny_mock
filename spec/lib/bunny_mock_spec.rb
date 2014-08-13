require 'spec_helper'

describe "BunnyMock Integration Tests", :integration => true do
  it "should handle the basics of message passing" do
    # Basic one-to-one queue/exchange setup.
    bunny = BunnyMock::Bunny.new
    queue = bunny.queue(
      "integration_queue",
      :durable     => true,
      :auto_delete => true,
      :exclusive   => false,
      :arguments   => {"x-ha-policy" => "all"}
    )
    exchange = bunny.exchange(
      "integration_exchange",
      :type        => :direct,
      :durable     => true,
      :auto_delete => true
    )
    queue.bind(exchange)

    # Basic assertions
    expect(queue.messages).to be_empty
    exchange.queues.should have(1).queue
    exchange.should be_bound_to "integration_queue"
    queue.default_consumer.message_count.should == 0

    # # Send some messages
    exchange.publish("Message 1")
    exchange.publish("Message 2")
    exchange.publish("Message 3")

    # # Verify state of the queue
    queue.messages.should have(3).messages
    queue.messages.should == [
      "Message 1",
      "Message 2",
      "Message 3"
    ]
    queue.snapshot_messages.should have(3).messages
    queue.snapshot_messages.should == [
      "Message 1",
      "Message 2",
      "Message 3"
    ]

    # # Here's what we expect to happen when we subscribe to this queue.
    handler = double("target")
    handler.should_receive(:handle_message).with("Message 1").ordered
    handler.should_receive(:handle_message).with("Message 2").ordered
    handler.should_receive(:handle_message).with("Message 3").ordered

    # # Read all those messages
    msg_count = 0
    queue.subscribe do |msg|
      handler.handle_message(msg[:payload])
      msg_count += 1
      queue.default_consumer.message_count.should == msg_count
    end
  end
end

describe BunnyMock do
  let(:bunny) { BunnyMock::Bunny.new(queue_exists?:true) }

  describe "#method_missing" do
    it "returns true for queue_exists?" do
      expect(bunny.queue_exists?('foo')).to eq(true)
    end
  end

  describe "#respond_to?" do
    it "returns true for queue_exists?" do
      expect(bunny.respond_to?(:queue_exists?)).to eq(true)
    end

    it "returns true for start?" do
      expect(bunny.respond_to?(:queue_exists?)).to eq(true)
    end

    it "returns false for bogus_method" do
      expect(bunny.respond_to?(:bogus_method)).to eq(false)
    end
  end

  describe "#start" do
    it "connects" do
      expect(bunny.start).to eq(:connected)
    end
  end

  describe "#qos" do
    it "returns :qos_ok" do
      expect(bunny.qos).to eq(:qos_ok)
    end
  end

  describe "#stop" do
    it "returns nil" do
      expect(bunny.stop).to eq(nil)
    end
  end

  describe "#close" do
    it "returns nil" do
      expect(bunny.close).to eq(nil)
    end
  end

  describe "#create_channel" do
    it "returns a new channel" do
      expect(bunny.create_channel).to be_a(BunnyMock::Channel)
    end
  end

  describe "#queue" do
    let(:queue_name) { 'my_queue' }
    let(:queue) { bunny.queue(queue_name, :durable => true) }

    it "is a BunnyMock::Queue" do
      expect(queue).to be_a(BunnyMock::Queue)
    end

    it "name is consistent" do
      expect(queue.name).to eq(queue_name)
    end

    it "is durable" do
      expect(queue).to be_durable
    end
  end

  describe "#exchange" do
    let(:exchange_name) { 'my_exch' }
    let(:exchange_type) { :direct }
    let(:exchange) { bunny.exchange(exchange_name, :type => exchange_type) }

    it "is a BunnyMock::Exchange" do
      expect(exchange).to be_a(BunnyMock::Exchange)
    end

    it "name is consistent" do
      expect(exchange.name).to eq(exchange_name)
    end

    it "type is consistent" do
      expect(exchange.type).to eq(exchange_type)
    end
  end
end

describe BunnyMock::Consumer do
  describe "#message_count" do
    let(:msg_count) { 5 }
    let(:consumer) { BunnyMock::Consumer.new(msg_count) }

    it "message count is consistent" do
      expect(consumer.message_count).to eq(msg_count)
    end
  end
end

describe BunnyMock::Queue do
  let(:queue_name) { "my_test_queue" }
  let(:queue_attrs) {
    {
      :durable     => true,
      :auto_delete => true,
      :exclusive   => false,
      :arguments   => {"x-ha-policy" => "all"}
    }
  }
  let(:queue) { BunnyMock::Queue.new(queue_name, queue_attrs) }

  describe "#name" do
    it "is consistent" do
      expect(queue.name).to eq(queue_name)
    end
  end

  describe "#attrs" do
    it "are consistent" do
      expect(queue.attrs).to eq(queue_attrs)
    end
  end

  describe "#messages" do
    it "is an Array" do
      expect(queue.messages).to be_an(Array)
    end

    it "should be empty" do
      expect(queue.messages).to be_empty
    end
  end

  describe "#messages" do
    it "is an Array" do
      expect(queue.snapshot_messages).to be_an(Array)
    end

    it "should be empty" do
      expect(queue.snapshot_messages).to be_empty
    end
  end

  describe "#delivery_count" do
    it "is initialized to zero" do
      expect(queue.delivery_count).to eq(0)
    end
  end

  describe "#subscribe" do
    let(:handler) { double("handler") }

    before(:each) do
      queue.messages = ["Ehh", "What's up Doc?"]
      handler.should_receive(:handle).with("Ehh").ordered
      handler.should_receive(:handle).with("What's up Doc?").ordered
      queue.subscribe { |msg| handler.handle(msg[:payload]) }
    end

    it "#messages are empty" do
      expect(queue.messages).to be_empty
    end

    it "#snapshot_messages are empty" do
      expect(queue.snapshot_messages).to be_empty
    end

    it "#delivery_count is accurate" do
      expect(queue.delivery_count).to eq(2)
    end

    it "verifies the mocks for rspec" do
      verify_mocks_for_rspec
    end
  end

  describe "#snapshot_messages" do
    let(:msg1) { 'Ehh' }
    let(:msg2) { "What's up Doc?" }
    let(:msg3) { 'Nothin'}
    let(:the_messages) { [msg1, msg2] }
    before(:each) do
      queue.messages = the_messages
    end

    it "are persistent" do
      snapshot = queue.snapshot_messages
      expect(snapshot).to eq(the_messages)
      snapshot.shift
      snapshot << msg3
      expect(snapshot).to eq([msg2, msg3])
      expect(queue.messages).to eq(the_messages)
      expect(queue.snapshot_messages).to eq(the_messages)
    end
  end

  describe "#bind" do
    let(:exchange_name) { 'my_test_exchange' }
    let(:exchange) { BunnyMock::Exchange.new(exchange_name,) }
    before(:each) { queue.bind(exchange) }

    it "is bound" do
      exchange.should be_bound_to "my_test_queue"
    end
  end

  describe "#default_consumer" do
    let(:delivery_count) { 5 }
    let(:consumer) { queue.default_consumer }
    before(:each) do
      queue.delivery_count = delivery_count
    end

    it "is the correct class" do
      expect(consumer).to be_a(BunnyMock::Consumer)
    end

    it "has a consistent message_count" do
      expect(consumer.message_count).to eq(delivery_count)
    end
  end

  describe "#method_missing" do
    it "queue is durable" do
      expect(queue).to be_durable
    end

    it "queue is auto_delete" do
      expect(queue.auto_delete).to be_true
    end

    it "queue is NOT exclusive" do
      expect(queue.exclusive).to be_false
    end

    it "queue arguments are consistent" do
      expect(queue.arguments).to eq({"x-ha-policy" => "all"})
    end

    it "raises a NoMethodError error for an unhandled method" do
      expect{queue.wtf}.to raise_error(NoMethodError)
    end
  end
end

describe BunnyMock::Exchange do
  let(:exchange_name) { "my_test_exchange" }
  let(:exchange_attrs) {
    {
      :type        => :direct,
      :durable     => true,
      :auto_delete => true
    }
  }
  let(:exchange) { BunnyMock::Exchange.new(exchange_name, exchange_attrs) }

  describe "#name" do
    it "returns the name" do
      expect(exchange.name).to eq(exchange_name)
    end
  end

  describe "#attrs" do
    it "returns the attributes" do
      expect(exchange.attrs).to eq(exchange_attrs)
    end
  end

  describe "#queues" do
    context "when the exchange is not bound to any queues" do
      it "is an Array" do
        expect(exchange.queues).to be_an(Array)
      end

      it "is empty" do
        expect(exchange.queues).to be_empty
      end
    end

    context "when the exchange is bound to a queue" do
      let(:queue) { BunnyMock::Queue.new("a_queue") }
      before(:each) { queue.bind(exchange) }

      it "has one queue" do
        exchange.queues.should have(1).queue
      end

      it "returns the correct queue" do
        expect(exchange.queues.first).to eq(queue)
      end
    end
  end

  describe "#bound_to?" do
    let(:queue_name) { 'a_queue' }
    let(:queue) { BunnyMock::Queue.new(queue_name) }
    before(:each) { queue.bind(exchange) }

    it "is bound to a queue" do
      expect(exchange).to be_bound_to(queue_name)
    end

    it "is not bound to another queue" do
      expect(exchange).to_not be_bound_to('another_queue')
    end
  end

  describe "#publish" do
    let(:the_message) { 'the message' }
    let(:queue1) { BunnyMock::Queue.new("queue1") }
    let(:queue2) { BunnyMock::Queue.new("queue2") }
    before(:each) do
      queue1.bind(exchange)
      queue2.bind(exchange)
      exchange.publish(the_message)
    end

    it "publishes the message" do
      expect(queue1.messages).to eq([the_message])
    end

    it "publishes the snapshot message" do
      expect(queue1.snapshot_messages).to eq([the_message])
    end

    it "publishes the message" do
      expect(queue2.messages).to eq([the_message])
    end

    it "publishes the snapshot message" do
      expect(queue2.snapshot_messages).to eq([the_message])
    end
  end

  describe "#method_missing" do
    it "exchange.type returns the correct type" do
      expect(exchange.type).to eq(:direct)
    end

    it "exchange.durable returns true" do
      expect(exchange.durable).to be_true
    end

    it "exchange is durable" do
      exchange.should be_durable
    end

    it "exchange auto_delete is true" do
      expect(exchange.auto_delete).to be_true
    end

    it "exchange is auto_delete" do
      exchange.should be_auto_delete
    end

    it "raises NoMethodError on invalid method call" do
      expect { exchange.wtf }.to raise_error NoMethodError
    end
  end
end
