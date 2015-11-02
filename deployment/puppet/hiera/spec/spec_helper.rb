require 'puppetlabs_spec_helper/module_spec_helper'

def puppet_debug_override
  if ENV['SPEC_PUPPET_DEBUG']
    Puppet::Util::Log.level = :debug
    Puppet::Util::Log.newdestination(:console)
  end
end

RSpec.configure do |config|
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end
end
