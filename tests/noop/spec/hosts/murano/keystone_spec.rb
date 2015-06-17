require 'spec_helper'
require 'shared-examples'
manifest = 'murano/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    public_address       = Noop.hiera('public_vip')
    internal_address     = Noop.hiera('management_vip', public_address)
    service_endpoint     = Noop.hiera('service_endpoint', internal_address)
    public_ssl           = Noop.hiera_structure('public_ssl/services')

    api_bind_port   = '8082'
    if public_ssl
      public_protocol = 'https'
    else
      public_protocol = 'http'
    end
    murano_password = Noop.hiera_structure('murano/user_password')
    tenant          = Noop.hiera_structure('murano/tenant', 'services')
    region          = Noop.hiera('region', 'RegionOne')
    public_url      = "#{public_protocol}://#{public_address}:#{api_bind_port}"
    admin_url       = "http://#{service_endpoint}:#{api_bind_port}"
    internal_url    = "http://#{service_endpoint}:#{api_bind_port}"

    it 'should declare murano::keystone::auth class correctly' do
      should contain_class('murano::keystone::auth').with(
                 'password'     => murano_password,
                 'service_type' => 'application_catalog',
                 'region'       => region,
                 'tenant'       => tenant,
                 'public_url'   => public_url,
                 'admin_url'    => admin_url,
                 'internal_url' => internal_url,
             )
    end
  end
  test_ubuntu_and_centos manifest
end
