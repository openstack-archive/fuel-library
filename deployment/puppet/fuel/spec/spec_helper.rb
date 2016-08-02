require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
  c.before :each do
    @default_facts = { :os_service_default => '<SERVICE DEFAULT>' }
  end
end

# TODO(aschultz): remove these and switch rspec-puppet-facts to use
# metadata.json values
def supported_os
    [
      { 'operatingsystem'        => 'CentOS',
        'operatingsystemrelease' => [ '7.0' ] },
      { 'operatingsystem'        => 'Ubuntu',
        'operatingsystemrelease' => [ '14.04' ] }
    ]
end

def puppet_debug_override
  if ENV['SPEC_PUPPET_DEBUG']
    Puppet::Util::Log.level = :debug
    Puppet::Util::Log.newdestination(:console)
  end
end
