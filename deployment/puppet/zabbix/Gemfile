source :rubygems

if ENV.key?('PUPPET_VERSION')
  puppetversion = "= #{ENV['PUPPET_VERSION']}"
else
  puppetversion = ['>= 3.0']
end

gem 'puppet', puppetversion
gem 'zabbixapi', ['>= 0.4.9']
 
group :test do
  gem 'rake', '>= 0.9.0'
  gem 'rspec', '>= 2.8.0'
  gem 'rspec-core', '>= 2.12.1'
  gem 'rspec-puppet', '>= 0.1.5'
  gem 'puppet-lint', '>= 0.3.2'
  gem 'puppetlabs_spec_helper', '>= 0.3.0'
  gem 'rspec-hiera-puppet', '>= 1.0.0'
end
