require 'spec_helper'

  describe 'openstack::firewall' do
    let(:params) { {:admin_nets   => ['admin_nets'],
                    :private_nets => ['private_nets'],
                    :public_nets  => ['public_nets'],
                    :storage_nets => ['storage_nets'],
                 } }
    let(:facts) { {:kernel => 'Linux'} }

    it 'should contain firewall rules for ssh' do
      should contain_openstack__firewall__multi_net('020 ssh').with(
        :port        => '22',
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['admin_nets', 'private_nets', 'storage_nets'],
      )
    end

    it 'should contain firewall rules for mysql' do
      should contain_openstack__firewall__multi_net('101 mysql').with(
        :port        => ['3306', '3307', '4567', '4568', '49000'],
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
    end

    it 'should contain firewall rule from private nova services' do
      should contain_openstack__firewall__multi_net('105 nova private - no ssl').with(
        :port        => ['8775', '5900-6100'],
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
    end

    it 'should contain firewall rules for rabbitmq' do
      should contain_openstack__firewall__multi_net('106 rabbitmq').with(
        :port        => ['4369','5672','5673','41055'],
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
    end

    it 'should contain firewall rules for memcache' do
      should contain_openstack__firewall__multi_net('107 memcache tcp').with(
        :port        => '11211',
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
      should contain_openstack__firewall__multi_net('107 memcache udp').with(
        :port        => '11211',
        :proto       => 'udp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
    end

    it 'should contain firewall rules for rsync' do
      should contain_openstack__firewall__multi_net('108 rsync').with(
        :port        => '873',
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['private_nets', 'storage_nets'],
      )
    end

    it 'should contain firewall rules for iscsi' do
      should contain_openstack__firewall__multi_net('109 iscsi').with(
        :port        => '3260',
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['storage_nets'],
      )
    end

    it 'should contain firewall rules for dns-server' do
      should contain_openstack__firewall__multi_net('111 dns-server udp').with(
        :port        => '53',
        :proto       => 'udp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
      should contain_openstack__firewall__multi_net('111 dns-server tcp').with(
        :port        => '53',
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
    end

    it 'should contain firewall rules for ntp-server' do
      should contain_openstack__firewall__multi_net('112 ntp-server').with(
        :port        => '123',
        :proto       => 'udp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
    end

    it 'should contain firewall rules for corosync' do
      should contain_openstack__firewall__multi_net('113 corosync-input').with(
        :port        => '5404',
        :proto       => 'udp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
      should contain_openstack__firewall__multi_net('114 corosync-output').with(
        :port        => '5405',
        :proto       => 'udp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
      should contain_openstack__firewall__multi_net('115 pcsd-server').with(
        :port        => '2224',
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
    end

    it 'should contain firewall rules for ovs' do
      should contain_openstack__firewall__multi_net('116 openvswitch db').with(
        :port        => '58882',
        :proto       => 'udp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
    end

    it 'should contain firewall rules for nrpe' do
      should contain_openstack__firewall__multi_net('117 nrpe-server').with(
        :port        => '5666',
        :proto       => 'udp',
        :action      => 'accept',
        :source_nets => ['admin_nets', 'private_nets'],
      )
    end

    it 'should contain firewall rules for libvirt' do
      should contain_openstack__firewall__multi_net('118 libvirt').with(
        :port        => '16509',
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
      should contain_openstack__firewall__multi_net('119 libvirt-migration').with(
        :port        => '49152-49215',
        :proto       => 'tcp',
        :action      => 'accept',
        :source_nets => ['private_nets'],
      )
    end
end
