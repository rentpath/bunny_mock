require 'rspec/autorun'

require 'simplecov'
SimpleCov.start do
  add_filter "/_spec.rb$/"
  add_filter "/vendor/"
end

require_relative '../lib/bunny_mock'

RSpec.configure do |config|
end
