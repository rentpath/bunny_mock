# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bunny_mock/version'

Gem::Specification.new do |spec|
  spec.name          = "bunny_mock"
  spec.version       = BunnyMock::VERSION
  spec.authors       = ["Scott W. Bradley", "Chris Blackburn", "Craig Demyanovich"]
  spec.email         = ["http://scottwb.com", "chris@midwiretech.com", "cdemyanovich@gmail.com"]
  spec.summary       = %q{Simple Bunny/RabbitMQ mock class in Ruby. Useful for mocking Bunny usage in test code.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/scottwb/bunny-mock"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "geminabox"
  spec.add_development_dependency "midwire_common"
end
