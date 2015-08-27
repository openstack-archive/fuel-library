require 'spec_helper'
require 'shared-examples'
manifest = 'ceilometer/radosgw_user.pp'

describe manifest do
  shared_examples 'catalog' do

    ceilometer_hash = Noop.hiera_structure 'ceilometer'
    storage_hash = Noop.hiera 'storage'

    if ceilometer_hash['enabled'] and storage_hash['objects_ceph']
      it 'should configure Ceilometer user in RadosGW' do
        should contain_ceilometer_radosgw_user('ceilometer').with(
          :caps => {'buckets' => '*', 'usage' => '*'}
        )
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end
