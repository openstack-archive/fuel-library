require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    public_address       = Noop.hiera('public_vip')
    internal_address     = Noop.hiera('management_vip', public_address)
    public_ssl           = Noop.hiera_structure('public_ssl/services')

    api_bind_port   = '8386'
    if public_ssl
      public_protocol = 'https'
    else
      public_protocol = 'http'
    end
    sahara_user     = Noop.hiera_structure('sahara_hash/user', 'sahara')
    sahara_password = Noop.hiera_structure('sahara_hash/user_password')
    tenant          = Noop.hiera_structure('sahara_hash/tenant', 'services')
    region          = Noop.hiera_structure('sahara_hash/region', 'RegionOne')
    service_name    = Noop.hiera_structure('sahara_hash/service_name', 'sahara')
    public_url      = "#{public_protocol}://#{public_address}:#{api_bind_port}/v1.1/%(tenant_id)s"
    admin_url       = "http://#{internal_address}:#{api_bind_port}/v1.1/%(tenant_id)s"
    internal_url    = "http://#{internal_address}:#{api_bind_port}/v1.1/%(tenant_id)s"

    it 'should declare sahara::keystone::auth class correctly' do
      should contain_class('sahara::keystone::auth').with(
        'auth_name'    => sahara_user,
        'password'     => sahara_password,
        'service_type' => 'data-processing',
        'service_name' => service_name,
        'region'       => region,
        'tenant'       => tenant,
        'public_url'   => public_url,
        'admin_url'    => admin_url,
        'internal_url' => internal_url,
      )
    end

    it 'should declare old sahara endpoint' do
     should contain_keystone_service('sahara-old').with(
       'ensure'      => 'present',
       'type'        => 'data_processing',
       'description' => 'OpenStack Data Processing',
     )
     should contain_keystone_endpoint("#{region}/sahara-old").with(
       'ensure'       => 'present',
       'public_url'   => public_url,
       'internal_url' => admin_url,
       'admin_url'    => admin_url,
     )
    end
  end
  test_ubuntu_and_centos manifest
end
