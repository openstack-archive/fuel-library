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

require 'spec_helper'
require 'shared-examples'
manifest = 'roles/controller.pp'




describe manifest do
  shared_examples 'catalog' do

    it 'should set vm.swappiness sysctl to 10' do
      should contain_sysctl('vm.swappiness').with(
        'val' => '10',
      )
    end
    it 'should make sure python-openstackclient package is installed' do
      should contain_package('python-openstackclient').with(
        'ensure' => 'installed',
      )
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

