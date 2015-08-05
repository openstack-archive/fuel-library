require 'spec_helper'
require 'shared-examples'
manifest = 'roles/cinder.pp'

describe manifest do
  shared_examples 'catalog' do

  storage_hash = Noop.hiera 'storage'

  if Noop.hiera 'use_ceph' and !(storage_hash['volumes_lvm'])
      it { should contain_class('ceph') }
  end

  it { should contain_package('python-amqp') }
  it { should contain_class('openstack::cinder') }

  it 'should disable use_stderr option' do
    should contain_cinder_config('DEFAULT/use_stderr').with(:value => 'false')
  end

  end
  test_ubuntu_and_centos manifest
end

