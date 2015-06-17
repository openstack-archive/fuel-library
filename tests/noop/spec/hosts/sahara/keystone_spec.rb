require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    public_vip    = Noop.hiera 'public_vip'
    admin_address = Noop.hiera 'management_vip'
    public_ssl    = Noop.hiera_structure 'public_ssl/services'

    api_bind_port   = '8386'
    if public_ssl
      public_address  = Noop.hiera_structure 'public_ssl/hostname'
      public_protocol = 'https'
    else
      public_address  = public_vip
      public_protocol = 'http'
    end
    sahara_user     = Noop.hiera_structure 'sahara/user', 'sahara'
    sahara_password = Noop.hiera_structure 'sahara/user_password'
    tenant          = Noop.hiera_structure 'sahara/tenant', 'services'
    region          = Noop.hiera_structure 'sahara/region', 'RegionOne'
    service_name    = Noop.hiera_structure 'sahara/service_name', 'sahara'
    public_url      = "#{public_protocol}://#{public_address}:#{api_bind_port}/v1.1/%(tenant_id)s"
    admin_url       = "http://#{admin_address}:#{api_bind_port}/v1.1/%(tenant_id)s"

    it 'should declare sahara::keystone::auth class correctly' do
      should contain_class('sahara::keystone::auth').with(
        'auth_name'    => sahara_user,
        'password'     => sahara_password,
        'service_type' => 'data_processing',
        'service_name' => service_name,
        'region'       => region,
        'tenant'       => tenant,
        'public_url'   => public_url,
        'admin_url'    => admin_url,
        'internal_url' => admin_url,
      )
    end
  end
  test_ubuntu_and_centos manifest
end
