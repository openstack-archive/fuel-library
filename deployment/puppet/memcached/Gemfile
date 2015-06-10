source "https://rubygems.org"

puppetversion = ENV.key?('PUPPET_VERSION') ? "= #{ENV['PUPPET_VERSION']}" : ['>= 3.3']
gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper', '>= 0.1.0'
gem 'rspec', '< 3.2.0', {"platforms"=>["ruby_18"]}
gem 'puppet-lint', '>= 0.3.2'
gem 'facter', '>= 1.7.0', "< 1.8.0"
gem 'rspec-puppet',		 '=1.0.1'
