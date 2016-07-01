require 'spec_helper'
require 'shared-examples'
manifest = 'tools/tools.pp'

atop_hash     = Noop.hiera 'atop', {}
atop_enabled  = Noop.puppet_function 'pick', atop_hash['service_enabled'], true
atop_interval = Noop.puppet_function 'pick', atop_hash['interval'], 20
atop_rotate   = Noop.puppet_function 'pick', atop_hash['rotate'], 7

describe manifest do
  shared_examples 'catalog' do
    it "should contain ssh host keygen exec for Debian OS only" do
      if facts[:osfamily] == 'Debian'
        should contain_exec('host-ssh-keygen').with(
          'command' => 'ssh-keygen -A'
        )
      else
        should_not contain_exec('host-ssh-keygen')
      end
    end

    it 'should declare tools classes' do
      should contain_class('osnailyfacter::atop').with(
          'service_enabled' => atop_enabled,
          'interval'        => atop_interval,
          'rotate'          => atop_rotate,
      )
    end
  end

  test_ubuntu_and_centos manifest
end
