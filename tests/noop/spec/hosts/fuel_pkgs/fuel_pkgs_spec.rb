# HIERA: neut_tun.ceph.murano.sahara.ceil-mongo
# HIERA: neut_tun.ceph.murano.sahara.ceil-primary-mongo
# HIERA: neut_vlan.murano.sahara.ceil-mongo
# HIERA: neut_vlan.murano.sahara.ceil-primary-mongo
# HIERA: neut_vlan.murano.sahara.ceil-cinder
# HIERA: neut_tun.ironic-ironic
# HIERA: neut_tun.ceph.murano.sahara.ceil-ceph-osd
# HIERA: neut_vlan.ceph-ceph-osd
# HIERA: neut_tun.ceph.murano.sahara.ceil-controller
# HIERA: neut_tun.ceph.murano.sahara.ceil-primary-controller
# HIERA: neut_tun.ironic-primary-controller
# HIERA: neut_tun.l3ha-primary-controller
# HIERA: neut_vlan.ceph-primary-controller
# HIERA: neut_vlan.dvr-primary-controller
# HIERA: neut_vlan.murano.sahara.ceil-controller
# HIERA: neut_vlan.murano.sahara.ceil-primary-controller
# HIERA: neut_tun.ceph.murano.sahara.ceil-compute
# HIERA: neut_vlan.ceph-compute
# HIERA: neut_vlan.murano.sahara.ceil-compute
# R_N: neut_gre.generate_vms
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

