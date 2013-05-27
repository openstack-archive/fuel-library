#source :rubygems
source 'https://rubygems.org'

gem 'rake'
gem 'puppet-lint'
gem 'rspec'
gem 'rspec-puppet'

## Will come in handy later on. But you could just use
# gem 'puppet'
puppetversion = ENV.key?('PUPPET_VERSION') ? "~> #{ENV['PUPPET_VERSION']}" : ['>= 2.7']
gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper'

