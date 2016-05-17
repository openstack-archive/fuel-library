require 'puppetlabs_spec_helper/module_spec_helper'
require 'shared_examples'

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
  c.before :each do
    @default_facts = {
      :ipaddress => '10.0.0.1',
      :hostname  => 'hostname.example.com',
      :concat_basedir => '/var/lib/puppet/concat',
    }
  end
end

at_exit { RSpec::Puppet::Coverage.report! }
