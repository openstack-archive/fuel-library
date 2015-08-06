source 'https://rubygems.org'

# Specify your gem's dependencies in puppet-syntax.gemspec
gemspec

# Override gemspec for CI matrix builds.
puppet_version = ENV['PUPPET_VERSION'] || '>2.7.0'
gem 'puppet', puppet_version
