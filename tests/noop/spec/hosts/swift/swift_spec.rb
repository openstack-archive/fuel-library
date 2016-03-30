# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'swift/swift.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should contain storage and proxy tasks' do
      should contain_class('openstack_tasks::swift::storage')
      should contain_class('openstack_tasks::swift::proxy')
    end
  end

  test_ubuntu_and_centos manifest
end

