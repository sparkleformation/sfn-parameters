$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'sfn-parameters/version'
Gem::Specification.new do |s|
  s.name = 'sfn-parameters'
  s.version = SfnParameters::VERSION.version
  s.summary = 'SparkleFormation Parameters Callback'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'http://github.com/sparkleformation/sfn-parameters'
  s.description = 'SparkleFormation Parameters Callback'
  s.license = 'Apache-2.0'
  s.require_path = 'lib'
  s.add_dependency 'sfn', '>= 3.0', '< 4.0'
  s.files = Dir['{lib,bin,docs}/**/*'] + %w(sfn-parameters.gemspec README.md CHANGELOG.md LICENSE)
end
