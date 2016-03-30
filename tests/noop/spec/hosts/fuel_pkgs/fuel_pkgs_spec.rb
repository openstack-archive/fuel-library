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
manifest = 'fuel_pkgs/fuel_pkgs.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should have ruby gem deep_merge installed' do
      case facts[:operatingsystem]
      when 'Ubuntu'
        ruby_deep_merge = 'ruby-deep-merge'
      when 'CentOS'
        ruby_deep_merge = 'rubygem-deep_merge'
      end

      should contain_package(ruby_deep_merge).with(
        'ensure' => 'present',
      )
    end

    ['fuel-ha-utils', 'fuel-misc'].each do |pkg|
      it "should install #{pkg} package" do
        should contain_package(pkg).with(
          'ensure' => 'present'
        )
      end
    end
  end

  test_ubuntu_and_centos manifest
end

