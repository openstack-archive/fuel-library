require 'spec_helper'
require 'shared-examples'
manifest = 'compute.pp'

describe manifest do

  shared_examples 'puppet catalogue' do
    it { should compile }

    use_neutron = Noop.fuel_settings['quantum'].to_s
    internal_address = Noop.node_hash['internal_address']

    # Libvirtd.conf
    it 'should configure listen_tls, listen_tcp and auth_tcp in libvirtd.conf' do
      should contain_augeas('libvirt-conf').with(
        'context' => '/files/etc/libvirt/libvirtd.conf',
        'changes' => [
          'set listen_tls 0',
          'set listen_tcp 1',
          'set auth_tcp none',
        ],
      )
    end

    # Nova.config options
    it 'nova config should have proper live_migration_flag' do
      should contain_nova_config('libvirt/live_migration_flag').with(
        'value' => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST',
      )
    end
    it 'nova config should have proper cinder_catalog_info' do
      should contain_nova_config('DEFAULT/cinder_catalog_info').with(
        'value' => 'volume:cinder:internalURL'
      )
    end
    it 'nova config should have proper use_syslog_rfc_format' do
      should contain_nova_config('DEFAULT/use_syslog_rfc_format').with(
        'value' => 'true',
      )
    end
    it 'nova config should have proper connection_type' do
      should contain_nova_config('DEFAULT/connection_type').with(
        'value' => 'libvirt',
      )
    end
    it 'nova config should have proper allow_resize_to_same_host' do
      should contain_nova_config('DEFAULT/allow_resize_to_same_host').with(
        'value' => 'true',
      )
    end
    it 'nova config should have report_interval set to 60' do
      should contain_nova_config('DEFAULT/report_interval').with(
        'value' => '60',
      )
    end
    it 'nova config should have service_down_time set to 180' do
      should contain_nova_config('DEFAULT/service_down_time').with(
        'value' => '180',
      )
    end
    if use_neutron
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

  end

  test_ubuntu_and_centos manifest
end


