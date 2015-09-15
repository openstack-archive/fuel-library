require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
  c.hiera_config = 'spec/fixtures/hiera.yaml'
end

at_exit { RSpec::Puppet::Coverage.report! }
