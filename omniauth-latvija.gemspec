# encoding: UTF-8
require File.expand_path('../lib/omniauth-latvija/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'omniauth-latvija'
  s.version     = OmniAuth::Latvija::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Edgars Beigarts']
  s.email       = ['edgars.beigarts@mitigate.dev']
  s.summary     = 'Latvija.lv authentication strategy for OmniAuth'
  s.description = s.summary

  s.files         = Dir.glob('{lib}/**/*') + %w(README.md LICENSE)
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.7'

  s.add_runtime_dependency 'omniauth', '~> 2.1'
  s.add_runtime_dependency 'xmlenc'
  s.add_runtime_dependency 'nokogiri', '>= 1.5.1'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'timecop'
end
