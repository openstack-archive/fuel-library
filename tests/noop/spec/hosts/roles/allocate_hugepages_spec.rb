# RUN: neut_tun.ceph.murano.sahara.ceil-mongo ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-cinder ubuntu
# RUN: neut_tun.ironic-ironic ubuntu
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
# R_N: neut_gre.generate_vms ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'roles/allocate_hugepages.pp'

describe manifest do
  shared_examples 'catalog' do
    hugepages = Noop.hiera 'hugepages', []
    unless hugepages.empty?
      mapped_sysfs_hugepages = {
        'node0/hugepages/hugepages-2048kB' => 512,
        'node1/hugepages/hugepages-1048576kB' => 8,
        'default' => 0
      }

      it "should allocate defined hugepages" do
        should contain_class('sysfs')
        should contain_sysfs_config_value('hugepages').with(
          'ensure'  => 'present',
          'name'    => '/etc/sysfs.d/hugepages.conf',
          'value'   => mapped_sysfs_hugepages,
          'sysfs'   => '/sys/devices/system/node/node*/hugepages/hugepages-*kB/nr_hugepages',
        )
        should contain_sysctl__value('vm.max_map_count').with_value('66570')
      end
    end
  end
  test_ubuntu_and_centos manifest
end
