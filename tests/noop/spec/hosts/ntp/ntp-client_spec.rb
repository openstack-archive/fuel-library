# RUN: neut_tun.ceph.murano.sahara.ceil-mongo ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-cinder ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-ceph-osd ubuntu
# RUN: neut_vlan.ceph-ceph-osd ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-compute ubuntu
# RUN: neut_vlan.ceph-compute ubuntu
# RUN: neut_vlan.murano.sahara.ceil-compute ubuntu
# RUN: neut_gre.generate_vms ubuntu

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

