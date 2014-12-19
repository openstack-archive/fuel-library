require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
module_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', '..', 'deployment', 'puppet'))

RSpec.configure do |c|
  c.module_path = module_path
  c.manifest = module_path + '/osnailyfacter/modular/hiera.pp'
  c.hiera_config = fixture_path + '/hiera.yaml'
  puts c.hiera_config

  c.before :each do
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
    # clear cached facts
    Facter::Util::Loader.any_instance.stubs(:load_all)
    Facter.clear
    Facter.clear_messages
  end
end
