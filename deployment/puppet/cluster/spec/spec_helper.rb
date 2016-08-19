require 'puppetlabs_spec_helper/module_spec_helper'
require 'shared_examples'
require 'rspec-puppet-facts'
include RspecPuppetFacts

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
end

at_exit { RSpec::Puppet::Coverage.report! }

def supported_os
  [
      {
          'operatingsystem' => 'CentOS',
          'operatingsystemrelease' => ['7.0'],
      },
      {
          'operatingsystem' => 'Ubuntu',
          'operatingsystemrelease' => ['14.04', '16.04'],
      },
  ]
end

def common_facts
  {
      :os_service_default => '<SERVICE DEFAULT>',
  }
end
