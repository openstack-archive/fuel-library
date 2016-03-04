require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw_keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    objects_ceph = Noop.hiera_structure('storage_hash/objects_ceph', false)
    if objects_ceph
      public_vip    = Noop.hiera('public_vip')
      admin_address = Noop.hiera('management_vip')
      public_ssl    = Noop.hiera_structure('public_ssl/services')
      region        = Noop.hiera_structure('region', 'RegionOne')

      if public_ssl
        public_address  = Noop.hiera_structure('public_ssl/hostname')
        public_protocol = 'https'
      else
        public_address  = public_vip
        public_protocol = 'http'
      end

      it 'should configure radosgw keystone endpoint' do
        should contain_keystone__resource__service_identity('radosgw').with(
          'configure_user'      => false,
          'configure_user_role' => false,
          'service_type'        => 'object-store',
          'service_description' => 'Openstack Object-Store Service',
          'service_name'        => 'swift',
          'region'              => region,
          'public_url'          => "#{public_protocol}://#{public_address}:8080/swift/v1",
          'admin_url'           => "http://#{admin_address}:8080/swift/v1",
          'internal_url'        => "http://#{admin_address}:8080/swift/v1",
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
