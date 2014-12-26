require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.before do
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
  end
  c.default_facts = { :concat_basedir => '/var/lib/puppet/concat' }
end
