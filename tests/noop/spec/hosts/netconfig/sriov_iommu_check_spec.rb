# RUN: neut_tun.ceph.murano.sahara.ceil-compute ubuntu
# RUN: neut_vlan.ceph-compute ubuntu
# RUN: neut_vlan.murano.sahara.ceil-compute ubuntu
# R_N: neut_gre.generate_vms ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/sriov_iommu_check.pp'
describe manifest do
  shared_examples 'catalog' do

    script = '/etc/puppet/modules/osnailyfacter/modular/netconfig/sriov_iommu_check.rb'

    it {
      should contain_exec('sriov_iommu_check').with(
        :command => "ruby #{script}"
      )
    }

  end

  test_ubuntu_and_centos manifest
end

