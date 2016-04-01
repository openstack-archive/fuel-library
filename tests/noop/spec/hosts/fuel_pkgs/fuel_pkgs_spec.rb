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

