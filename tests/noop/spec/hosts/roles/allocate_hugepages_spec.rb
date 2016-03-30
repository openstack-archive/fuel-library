# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.yaml
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml
# HIERA: neut_vxlan_dvr.murano.sahara-controller.yaml
# HIERA: neut_vxlan_dvr.murano.sahara-compute.yaml
# HIERA: neut_vxlan_dvr.murano.sahara-cinder.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-controller.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-compute.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml
# HIERA: neut_vlan.ironic.controller.yaml
# HIERA: neut_vlan.ironic.conductor.yaml
# HIERA: neut_vlan.compute.ssl.yaml
# HIERA: neut_vlan.compute.ssl.overridden.yaml
# HIERA: neut_vlan.compute.nossl.yaml
# HIERA: neut_vlan.cinder-block-device.compute.yaml
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph.yaml
# HIERA: neut_vlan.ceph.compute-ephemeral-ceph.yaml
# HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml
# HIERA: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml
# HIERA: neut_gre.generate_vms.yaml
require 'spec_helper'
require 'shared-examples'
manifest = 'roles/allocate_hugepages.pp'

describe manifest do
  shared_examples 'catalog' do
    hugepages = Noop.hiera 'hugepages', []
    mapped_sysfs_hugepages = hugepages.empty? ? { 'default' => 0 } : {
      'node0/hugepages/hugepages-2048kB' => 512,
      'node1/hugepages/hugepages-1048576kB' => 8,
      'default' => 0
    }
    max_map_count = hugepages.empty? ? '65530' : '66570'

    it "should allocate defined hugepages" do
      should contain_class('sysfs')
      should contain_sysfs_config_value('hugepages').with(
        'ensure'  => 'present',
        'name'    => '/etc/sysfs.d/hugepages.conf',
        'value'   => mapped_sysfs_hugepages,
        'sysfs'   => '/sys/devices/system/node/node*/hugepages/hugepages-*kB/nr_hugepages',
        'exclude' => '/sys/devices/system/node/node*/hugepages/hugepages-1048576kB/nr_hugepages',
      )
      should contain_sysctl__value('vm.max_map_count').with_value(max_map_count)
    end
  end
  test_ubuntu_and_centos manifest
end
