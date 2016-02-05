require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/radosgw_user.pp'

# HIERA: neut_vlan_l3ha.ceph.ceil-controller neut_vlan.ceph.ceil-primary-controller.overridden_ssl
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do

    ceilometer_hash = task.hiera_structure 'ceilometer'
    storage_hash = task.hiera 'storage'

    if ceilometer_hash['enabled'] and storage_hash['objects_ceph']
      it 'should configure Ceilometer user in RadosGW' do
        should contain_ceilometer_radosgw_user('ceilometer').with(
          :caps => {'buckets' => 'read', 'usage' => 'read'}
        )
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end
