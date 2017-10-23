$:.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'bundler/setup'

require 'simplecov'
SimpleCov.start

require 'rspec'
require 'rack/test'

require 'omniauth'
require 'omniauth/test'
require 'omniauth-latvija'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.extend  OmniAuth::Test::StrategyMacros, :type => :strategy
end

