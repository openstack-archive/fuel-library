# RUN: neut_gre.generate_vms ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph ubuntu
# RUN: neut_vlan.cinder-block-device.compute ubuntu
# RUN: neut_vlan.compute.nossl ubuntu
# RUN: neut_vlan.compute.ssl ubuntu
# RUN: neut_vlan.compute.ssl.overridden ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute ubuntu

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

