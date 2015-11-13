require 'spec_helper'

  describe 'openstack::firewall' do
    let(:params) { {:admin_nets   => ['10.20.0.0/24'],
                    :private_nets => ['10.20.1.0/24'],
                    :public_nets  => ['10.20.2.0/24'],
                    :storage_nets => ['10.20.3.0/24'],
                 } }
    let(:facts) { {:kernel => 'Linux'} }

    it 'should contain firewall rules for ssh' do
      should contain_openstack__firewall__multi_net('020 ssh')
    end

    it 'should contain firewall rules for mysql' do
      should contain_openstack__firewall__multi_net('101 mysql')
    end

    it 'should contain firewall rule from private nova services' do
      should contain_openstack__firewall__multi_net('105 nova private - no ssl')
    end

    it 'should contain firewall rules for rabbitmq' do
      should contain_openstack__firewall__multi_net('106 rabbitmq')
    end

    it 'should contain firewall rules for memcache' do
      should contain_openstack__firewall__multi_net('107 memcache tcp')
      should contain_openstack__firewall__multi_net('107 memcache udp')
    end

    it 'should contain firewall rules for rsync' do
      should contain_openstack__firewall__multi_net('108 rsync')
    end

    it 'should contain firewall rules for iscsi' do
      should contain_openstack__firewall__multi_net('109 iscsi')
    end

    it 'should contain firewall rules for dns-server' do
      should contain_openstack__firewall__multi_net('111 dns-server udp')
      should contain_openstack__firewall__multi_net('111 dns-server tcp')
    end

    it 'should contain firewall rules for ntp-server' do
      should contain_openstack__firewall__multi_net('112 ntp-server')
    end

    it 'should contain firewall rules for corosync' do
      should contain_openstack__firewall__multi_net('113 corosync-input')
      should contain_openstack__firewall__multi_net('114 corosync-output')
      should contain_openstack__firewall__multi_net('115 pcsd-server')
    end

    it 'should contain firewall rules for ovs' do
      should contain_openstack__firewall__multi_net('116 openvswitch db')
    end

    it 'should contain firewall rules for nrpe' do
      should contain_openstack__firewall__multi_net('117 nrpe-server')
    end

    it 'should contain firewall rules for libvirt' do
      should contain_openstack__firewall__multi_net('118 libvirt')
      should contain_openstack__firewall__multi_net('119 libvirt-migration')
    end


end
