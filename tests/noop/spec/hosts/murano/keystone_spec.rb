require 'spec_helper'
require 'shared-examples'
manifest = 'murano/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    public_ip            = Noop.hiera('public_vip')
    internal_address     = Noop.hiera('management_vip', public_ip)
    service_endpoint     = Noop.hiera('service_endpoint', internal_address)
    public_ssl           = Noop.hiera_structure('public_ssl/services')

    api_bind_port   = '8082'
    if public_ssl
      public_protocol = 'https'
      public_address = Noop.hiera_structure('public_ssl/hostname')
    else
      public_protocol = 'http'
      public_address = public_ip
    end
    murano_password = Noop.hiera_structure('murano_hash/user_password')
    tenant          = Noop.hiera_structure('murano_hash/tenant', 'services')
    region          = Noop.hiera('region', 'RegionOne')
    public_url      = "#{public_protocol}://#{public_address}:#{api_bind_port}"
    admin_url       = public_url
    internal_url    = "http://#{service_endpoint}:#{api_bind_port}"

    it 'should declare murano::keystone::auth class correctly' do
      should contain_class('murano::keystone::auth').with(
                 'password'     => murano_password,
                 'service_type' => 'application_catalog',
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
