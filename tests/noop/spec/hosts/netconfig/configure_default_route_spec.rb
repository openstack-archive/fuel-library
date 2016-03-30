# HIERA: neut_gre.generate_vms
# HIERA: neut_vlan.ceph.ceil-compute.overridden_ssl
# HIERA: neut_vlan.ceph.compute-ephemeral-ceph
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# HIERA: neut_vlan.cinder-block-device.compute
# HIERA: neut_vlan.compute.nossl
# HIERA: neut_vlan.compute.ssl
# HIERA: neut_vlan.compute.ssl.overridden
# HIERA: neut_vlan_l3ha.ceph.ceil-ceph-osd
# HIERA: neut_vlan_l3ha.ceph.ceil-compute
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-mongo
# HIERA: neut_vxlan_dvr.murano.sahara-cinder
# HIERA: neut_vxlan_dvr.murano.sahara-compute

require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/configure_default_route.pp'

describe manifest do
  shared_examples 'catalog' do

    use_neutron      = Noop.hiera 'use_neutron'

    it { should contain_class('l23network').with('use_ovs' => use_neutron) }

  end

  test_ubuntu_and_centos manifest
end

