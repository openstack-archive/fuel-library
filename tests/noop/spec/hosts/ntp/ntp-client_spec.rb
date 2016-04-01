# RUN: neut_gre.generate_vms ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl ubuntu
# RUN: neut_vlan.cinder-block-device.compute ubuntu
# RUN: neut_vlan.compute.nossl ubuntu
# RUN: neut_vlan.compute.ssl.overridden ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-client.pp'

describe manifest do

  shared_examples 'catalog' do

    ntp_server_roles = Noop.hiera('ntp_server_roles', ['controller', 'primary-controller'])
    is_ntp_server = Noop.puppet_function 'roles_include', ntp_server_roles

    it 'should set up NTP' do
      management_vrouter_vip = Noop.hiera('management_vrouter_vip')
      servers = Noop.hiera('ntp_servers', management_vrouter_vip)

      unless is_ntp_server
        should contain_class('ntp').with(
          :servers         => servers,
          :service_ensure  => 'running',
          :service_enable  => 'true',
          :disable_monitor => 'true',
          :iburst_enable   => 'true',
          :tinker          => 'true',
          :panic           => '0',
          :stepout         => '5',
          :minpoll         => '3',
        )
      end
    end

    it 'should override ntp service on Ubuntu' do
      if facts[:operatingsystem] == 'Ubuntu'
        should contain_tweaks__ubuntu_service_override('ntpd').with(
          :package_name => 'ntp',
          :service_name => 'ntp',
        )
      end
    end
  end

  test_ubuntu_and_centos manifest
end

