require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/create_cinder_types.pp'

describe manifest do
  shared_examples 'catalog' do

    access_admin         = task.hiera_structure('access_hash', {})
    public_vip           = task.hiera('public_vip')
    region               = task.hiera('region', 'RegionOne')
    volume_backend_names = task.hiera_structure 'storage_hash/volume_backend_names'
    available_backends   = volume_backend_names.delete_if { |key,value| ! value }
    backend_names        = available_backends.keys

    if task.hiera_structure('use_ssl', false)
      public_protocol = 'https'
      public_address = task.hiera_structure('use_ssl/keystone_public_hostname')
      admin_protocol = 'https'
      admin_address = task.hiera_structure('use_ssl/keystone_admin_hostname')
    elsif task.hiera_structure('public_ssl/services')
      public_protocol = 'https'
      public_address = task.hiera_structure('public_ssl/hostname')
    else
      public_protocol = 'http'
      public_address = task.hiera('public_vip')
    end

    backend_names.each do |backend_name|
      it 'should contain creating cinder types' do
         should contain_create_cinder_types(backend_name).with(
           'volume_backend_names' => available_backends,
           'os_password'          => access_admin['password'],
           'os_tenant_name'       => access_admin['tenant'],
           'os_username'          => access_admin['user'],
           'os_auth_url'          => "#{public_protocol}://#{public_address}:5000/v2.0/",
           'os_region_name'       => region,
         )
      end
    end

  end
  test_ubuntu_and_centos manifest
end
