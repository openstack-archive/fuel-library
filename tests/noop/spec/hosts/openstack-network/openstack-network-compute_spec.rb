require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/openstack-network-compute.pp'

describe manifest do
  shared_examples 'puppet catalogue' do

    # TODO All this stuff should be moved to shared examples controller* tests.

    settings = Noop.fuel_settings

    # Test that catalog compiles and there are no dependency cycles in the graph
    it { should compile }

    # Network
    if settings['quantum']
      it 'should declare openstack::network with neutron enabled' do
        should contain_class('openstack::network').with(
          'neutron_server' => 'false',
        )
      end
    else
      it 'should declare openstack::network with neutron disabled' do
        should contain_class('openstack::network').with(
          'neutron_server' => 'false',
        )
      end
    end

    if settings['quantum']
      it 'should create /etc/libvirt/qemu.conf file that notifies libvirt service' do
        should contain_file('/etc/libvirt/qemu.conf').with(
          'ensure' => 'present',
          'source' => 'puppet:///modules/nova/libvirt_qemu.conf',
        ).that_notifies('Service[libvirt]')
      end
      it 'should configure linuxnet_interface_driver and linuxnet_ovs_integration_bridge' do
        should contain_nova_config('DEFAULT/linuxnet_interface_driver').with(
          'value' => 'nova.network.linux_net.LinuxOVSInterfaceDriver',
        )
        should contain_nova_config('DEFAULT/linuxnet_ovs_integration_bridge').with(
          'value' => 'br-int',
        )
      end
      it 'should configure net.bridge.bridge* keys that come before libvirt service' do
        should contain_augeas('sysctl-net.bridge.bridge-nf-call-arptables').with(
          'context' => '/files/etc/sysctl.conf',
          'changes' => "set net.bridge.bridge-nf-call-arptables '1'",
        ).that_comes_before('Service[libvirt]')
        should contain_augeas('sysctl-net.bridge.bridge-nf-call-iptables').with(
          'context' => '/files/etc/sysctl.conf',
          'changes' => "set net.bridge.bridge-nf-call-iptables '1'",
        ).that_comes_before('Service[libvirt]')
        should contain_augeas('sysctl-net.bridge.bridge-nf-call-ip6tables').with(
          'context' => '/files/etc/sysctl.conf',
          'changes' => "set net.bridge.bridge-nf-call-ip6tables '1'",
        ).that_comes_before('Service[libvirt]')
      end
    else
      it 'should configure multi_host, send_arp_for_ha, metadata_host in nova.conf for nova-network' do
        should contain_nova_config('DEFAULT/multi_host').with(
          'value' => 'True',
        )
        should contain_nova_config('DEFAULT/send_arp_for_ha').with(
          'value' => 'True',
        )
        should contain_nova_config('DEFAULT/metadata_host').with(
          'value' => internal_address,
        )
      end
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

