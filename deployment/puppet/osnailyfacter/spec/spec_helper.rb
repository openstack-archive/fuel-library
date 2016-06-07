require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'webmock/rspec'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "lib"))

# Add fixture lib dirs to LOAD_PATH. Work-around for PUP-3336
Dir["#{fixture_path}/modules/*/lib"].entries.each do |lib_dir|
  $LOAD_PATH << lib_dir
end

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.mock_with(:mocha)
  c.alias_it_should_behave_like_to :it_configures, 'configures'

  # Function fqdn_rand was changed in Puppet 4.4.0, yielding different results
  # for identical input before and after the change
  # Spec tests for function amqp_hosts break, unless there is a different output check
  # for Puppet befor and after 4.4.0
  if Puppet.version < '4.4.0'
    c.before(:all) { @ampq_host_value = '192.168.0.3:5673, 192.168.0.1:5673, 192.168.0.2:5673' }
  else
    c.before(:all) { @ampq_host_value = '192.168.0.1:5673, 192.168.0.2:5673, 192.168.0.3:5673' }
  end
end

def puppet_debug_override
  if ENV['SPEC_PUPPET_DEBUG']
    Puppet::Util::Log.level = :debug
    Puppet::Util::Log.newdestination(:console)
  end
end

###
