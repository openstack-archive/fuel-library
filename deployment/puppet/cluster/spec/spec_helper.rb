require 'puppetlabs_spec_helper/module_spec_helper'
require 'shared_examples'

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
end

at_exit { RSpec::Puppet::Coverage.report! }

def puppet_debug_override
  return unless ENV['SPEC_PUPPET_DEBUG']
  Puppet::Util::Log.level = :debug
  Puppet::Util::Log.newdestination(:console)
end
