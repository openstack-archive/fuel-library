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

  keystone_auth_host = Noop.hiera 'service_endpoint'
  auth_uri           = "http://#{keystone_auth_host}:5000/"
  identity_uri       = "http://#{keystone_auth_host}:5000/"

  it 'ensures cinder_config contains auth_uri and identity_uri ' do
    should contain_cinder_config('keystone_authtoken/auth_uri').with(:value  => auth_uri)
    should contain_cinder_config('keystone_authtoken/identity_uri').with(:value  => identity_uri)
  end

  end
  test_ubuntu_and_centos manifest
end

