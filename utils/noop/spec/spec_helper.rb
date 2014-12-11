require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet'

logs_dir = ENV['PUPPET_LOGS_DIR'] || 'none'

RSpec.configure do |c|
  c.module_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'deployment', 'puppet'))
  c.manifest = File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'deployment', 'puppet', 'osnailyfacter', 'examples', 'site.pp'))
  c.expose_current_running_example_as :example

  c.before :each do |test|
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
    # clear cached facts
    Facter::Util::Loader.any_instance.stubs(:load_all)
    Facter.clear
    Facter.clear_messages

    # Puppet logs creation for catalog compilation test only
    if logs_dir != 'none' and test.metadata[:example_group][:full_description] =~ /yaml\)$/
      descr = test.metadata[:example_group][:full_description].gsub(/\s+/, '_').gsub(/\(|\)/, '')
      @file = "#{logs_dir}/#{descr}.log"
      Puppet::Util::Log.newdestination(@file)
      Puppet::Util::Log.level = :debug
    end
  end

  c.after :each do |test|
    # Puppet logs cleanup for catalog compilation test only
    if logs_dir != 'none' and test.metadata[:example_group][:full_description] =~ /yaml\)$/
      Puppet::Util::Log.close_all
      descr = test.metadata[:example_group][:full_description].gsub(/\s+/, '_').gsub(/\(|\)/, '')
      if example.exception == nil
        # Remove puppet log if there are no compilation errors
        File.delete("#{logs_dir}/#{descr}.log")
      end
    end
  end

end
