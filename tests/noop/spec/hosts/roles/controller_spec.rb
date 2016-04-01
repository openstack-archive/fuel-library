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

