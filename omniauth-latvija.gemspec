# encoding: UTF-8
require File.expand_path('../lib/omniauth-latvija/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'omniauth-latvija'
  s.version     = OmniAuth::Latvija::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Edgars Beigarts']
  s.email       = ['edgars.beigarts@makit.lv']
  s.summary     = 'Latvija.lv authentication strategy for OmniAuth'
  s.description = s.summary

  s.files         = Dir.glob('{lib}/**/*') + %w(README.md LICENSE)
  s.require_paths = ['lib']

  s.add_runtime_dependency 'omniauth', '~> 1.0'
  s.add_runtime_dependency 'xmlenc'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.10'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rack-test'
end
