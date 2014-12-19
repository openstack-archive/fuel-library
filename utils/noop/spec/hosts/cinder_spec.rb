require 'spec_helper'
require File.join File.dirname(__FILE__), '../shared-examples'
manifest = 'cinder.pp'

describe manifest do

  shared_examples 'puppet catalogue' do
    it { should compile }
    it 'should configure linuxnet_interface_driver and linuxnet_ovs_integration_bridge' do
      should contain_nova_config('DEFAULT/linuxnet_interface_driver').with(
        'value' => 'nova.network.linux_net.LinuxOVSInterfaceDriver',
      )
      should contain_nova_config('DEFAULT/linuxnet_ovs_integration_bridge').with(
        'value' => 'br-int',
      )
    end
  end

  test_ubuntu_and_centos manifest
end
