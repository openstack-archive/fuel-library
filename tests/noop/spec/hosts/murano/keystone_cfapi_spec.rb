require 'spec_helper'
require 'shared-examples'
manifest = 'murano/keystone_cfapi.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:service_endpoint) { Noop.hiera 'service_endpoint' }
    let(:network_scheme) { Noop.hiera_hash 'network_scheme' }
    api_bind_port = '8083'

    internal_protocol = 'http'
    internal_address = Noop.hiera('service_endpoint')
    admin_protocol = 'http'
    admin_address = internal_address

    if Noop.hiera_structure('use_ssl', false)
      public_protocol = 'https'
      public_address = Noop.hiera_structure('use_ssl/murano_public_hostname')
      internal_protocol = 'https'
      internal_address = Noop.hiera_structure('use_ssl/murano_internal_hostname')
      admin_protocol = 'https'
      admin_address = Noop.hiera_structure('use_ssl/murano_admin_hostname')
    elsif Noop.hiera_structure('public_ssl/services')
      public_protocol = 'https'
      public_address = Noop.hiera_structure('public_ssl/hostname')
    else
      public_protocol = 'http'
      public_address = Noop.hiera 'public_vip'
    end
    public_url = "#{public_protocol}://#{public_address}:#{api_bind_port}"
    internal_url = "#{internal_protocol}://#{internal_address}:#{api_bind_port}"
    admin_url = "#{admin_protocol}://#{admin_address}:#{api_bind_port}"


    let(:region) { Noop.hiera('region', 'RegionOne') }
    let(:tenant) { Noop.hiera_structure('murano_hash/tenant', 'services') }

    let(:murano_password) { Noop.hiera_structure('murano_hash/user_password') }

    ##########################################################################

    it 'should declare murano::keystone::cfapi_auth class correctly' do
      should contain_class('murano::keystone::cfapi_auth').with(
                 'password'     => murano_password,
                 'service_type' => 'service_broker',
                 'region'       => region,
                 'tenant'       => tenant,
                 'public_url'   => public_url,
                 'internal_url' => internal_url,
                 'admin_url'    => admin_url
             )
    end

  end
  test_ubuntu_and_centos manifest
end
