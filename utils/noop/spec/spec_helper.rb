require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet'

RSpec.configure do |c|
  c.module_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'deployment', 'puppet'))
  c.manifest = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'deployment', 'puppet', 'osnailyfacter', 'examples', 'site.pp'))

  c.before :each do
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
    # clear cached facts
    Facter::Util::Loader.any_instance.stubs(:load_all)
    Facter.clear
    Facter.clear_messages
  end
end
