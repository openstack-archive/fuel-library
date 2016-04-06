# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
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

