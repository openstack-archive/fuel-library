# HIERA: neut_gre.generate_vms
# HIERA: neut_vlan.ceph.ceil-compute.overridden_ssl
# HIERA: neut_vlan.ceph.compute-ephemeral-ceph
# HIERA: neut_vlan.cinder-block-device.compute
# HIERA: neut_vlan.compute.nossl
# HIERA: neut_vlan.compute.ssl
# HIERA: neut_vlan.compute.ssl.overridden
# HIERA: neut_vlan_l3ha.ceph.ceil-compute
# HIERA: neut_vxlan_dvr.murano.sahara-compute

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

