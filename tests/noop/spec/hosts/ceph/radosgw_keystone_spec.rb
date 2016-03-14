require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw_keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    radosgw_enabled = Noop.hiera_structure('storage/objects_ceph', false)
    if radosgw_enabled
      region            = Noop.hiera('region', 'RegionOne')
      internal_protocol = 'http'
      internal_address  = Noop.hiera('management_vip')
      admin_protocol    = 'http'
      admin_address     = internal_address

      if Noop.hiera_structure('use_ssl', false)
        public_protocol = 'https'
        public_address  = Noop.hiera_structure('use_ssl/radosgw_public_hostname')
        internal_protocol = 'https'
        internal_address = Noop.hiera_structure('use_ssl/radosgw_internal_hostname')
        admin_protocol = 'https'
        admin_address = Noop.hiera_structure('use_ssl/radosgw_admin_hostname')
      elsif Noop.hiera_structure('public_ssl/services')
        public_protocol = 'https'
        public_address  = Noop.hiera_structure('public_ssl/hostname')
      else
        public_address  = Noop.hiera('public_vip')
        public_protocol = 'http'
      end

      public_url   = "#{public_protocol}://#{public_address}:8004/v1/%(tenant_id)s"
      internal_url = "#{internal_protocol}://#{internal_address}:8004/v1/%(tenant_id)s"
      admin_url    = "#{admin_protocol}://#{admin_address}:8004/v1/%(tenant_id)s"

      it 'should configure radosgw keystone endpoint' do
        should contain_keystone__resource__service_identity('radosgw').with(
          'configure_user'      => false,
          'configure_user_role' => false,
          'service_type'        => 'object-store',
          'service_description' => 'Openstack Object-Store Service',
          'service_name'        => 'swift',
          'region'              => region,
          'public_url'          => public_url,
          'admin_url'           => admin_url,
          'internal_url'        => internal_url,
        )
      end
    end
  test_ubuntu_and_centos manifest
end
