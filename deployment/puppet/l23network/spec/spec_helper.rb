require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "lib"))

# Add fixture lib dirs to LOAD_PATH. Work-around for PUP-3336
if Puppet.version < '4.0.0'
  Dir["#{fixture_path}/modules/*/lib"].entries.each do |lib_dir|
    $LOAD_PATH << lib_dir
  end
end

Puppet::Util::Log.level = :debug
Puppet::Util::Log.newdestination(:console)

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.mock_with(:mocha)
end

###
