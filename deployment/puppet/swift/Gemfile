source 'https://rubygems.org'

group :development, :test do
  gem 'puppetlabs_spec_helper', '~> 0.4.1', :require => false
  gem 'rspec', '~> 2.14.0'
  gem 'mocha', '~> 0.10.5'
  gem 'rspec-puppet', '~> 1.0.1'
  gem 'puppet-lint', '~> 0.3.2'
  gem 'rake', '10.1.1'
  gem 'webmock', '~> 1.18.0'
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
