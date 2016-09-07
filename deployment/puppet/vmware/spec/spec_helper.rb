require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
end

def common_facts
  {
      :os_service_default => '<SERVICE DEFAULT>',
      :os_package_type => 'debian',
  }
end
