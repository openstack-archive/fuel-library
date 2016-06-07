source 'https://rubygems.org'

group :development, :test do
  gem 'rake',                    :require => false
  gem 'pry',                     :require => false
  gem 'rspec', '~>3.3',          :require => false
  gem 'rspec-puppet', '~>2.2.0', :require => false
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'puppet-lint', '~> 1.1'
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
