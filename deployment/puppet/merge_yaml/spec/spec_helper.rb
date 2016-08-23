require 'puppetlabs_spec_helper/module_spec_helper'

require 'rspec-puppet-facts'
include RspecPuppetFacts

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

def puppet_debug_override
  return unless ENV['SPEC_PUPPET_DEBUG']
  Puppet::Util::Log.level = :debug
  Puppet::Util::Log.newdestination(:console)
end

RSpec.configure do |config|
  config.mock_with :rspec
end
