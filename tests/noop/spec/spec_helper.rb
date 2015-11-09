require 'rubygems'
require 'puppet'
require 'hiera_puppet'
require 'rspec-puppet'
require 'rspec-puppet-utils'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'yaml'
require 'fileutils'
require 'find'

class Noop
  lib_dir = File.expand_path File.absolute_path File.join File.dirname(__FILE__), 'lib'
  submodules = %w(catalog coverage debug facts files helpers overrides path spec tasks)

  submodules.each do |submodule|
    require File.join lib_dir, submodule
  end
end

Noop.setup_overrides

# Add fixture lib dirs to LOAD_PATH. Work-around for PUP-3336
if Puppet.version < '4.0.0'
  Dir["#{Noop.module_path}/*/lib"].entries.each do |lib_dir|
    $LOAD_PATH << lib_dir
  end
end

RSpec.configure do |c|
  c.module_path = Noop.module_path
  c.expose_current_running_example_as :example

  c.pattern = 'hosts/**'

  c.before :each do
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
    # clear cached facts
    Facter::Util::Loader.any_instance.stubs(:load_all)
    Facter.clear
    Facter.clear_messages
  end

  c.mock_with :rspec

end

Noop.coverage_simplecov if ENV['SPEC_COVERAGE']
