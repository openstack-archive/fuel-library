# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'umm/umm.pp'

describe manifest do
  shared_examples 'catalog' do
    role = Noop.hiera 'role'
    it 'ensures fuel-umm installed and /etc/umm.conf is present' do
      if role == 'primary-controller' or role == 'controller'
        should contain_package('fuel-umm')
        should contain_file('umm_config').with(
          'ensure' => 'present',
          'path'   => '/etc/umm.conf',
        )
      end
    end
  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

