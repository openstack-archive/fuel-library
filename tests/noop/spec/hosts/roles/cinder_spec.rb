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

  if Noop.hiera_structure('use_ssl')
    internal_auth_protocol = 'https'
    internal_auth_address  = Noop.hiera_structure('use_ssl/keystone_internal_hostname')
    glance_protocol = 'https'
    glance_internal_address = Noop.hiera_structure('use_ssl/glance_internal_hostname')
  else
    internal_auth_protocol = 'http'
    internal_auth_address  = Noop.hiera 'service_endpoint'
    glance_protocol = 'http'
    glance_internal_address = Noop.hiera('management_vip')
  end
  auth_uri           = "#{internal_auth_protocol}://#{internal_auth_address}:5000/"
  glance_api_servers = "#{glance_protocol}://#{glance_internal_address}:9292"

  it 'should contain correct glance api servers addresses' do
    should contain_class('openstack::cinder').with(
      'glance_api_servers' => glance_api_servers
    )
  end

  it 'ensures cinder_config contains auth_uri and identity_uri ' do
    should contain_cinder_config('keystone_authtoken/auth_uri').with(:value  => auth_uri)
    should contain_cinder_config('keystone_authtoken/identity_uri').with(:value  => auth_uri)
    should contain_cinder_config('DEFAULT/auth_strategy').with(:value  => 'keystone')
  end

  it 'should disable use_stderr option' do
    should contain_cinder_config('DEFAULT/use_stderr').with(:value => 'false')
  end

  end
  test_ubuntu_and_centos manifest
end

