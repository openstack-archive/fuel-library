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
manifest = 'cgroups/cgroups.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :prepare_cgroups_hash
    MockFunction.new(:prepare_cgroups_hash) do |function|
      allow(function).to receive(:call).and_return({})
    end
  end

  shared_examples 'catalog' do
    cgroups_hash = Noop.hiera_structure('cgroups', nil)
    if cgroups_hash
      it 'should declare cgroups class correctly' do
        should contain_class('cgroups').with(
          'cgroups_set'  => {},
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
