require 'spec_helper'
require 'shared-examples'
manifest = 'murano/keystone.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:service_endpoint) { Noop.hiera 'service_endpoint' }
    let(:network_scheme) { Noop.hiera_hash 'network_scheme' }
    let(:public_vip) { Noop.hiera 'public_vip' }
    let(:public_ssl) { Noop.hiera_structure('public_ssl/services') }
    let(:public_ssl_hostname) { Noop.hiera_structure('public_ssl/hostname') }
    let(:api_bind_port) { '8082' }

    let(:admin_url) { "http://#{service_endpoint}:#{api_bind_port}" }
    let(:public_url) { "#{public_protocol}://#{public_address}:#{api_bind_port}" }

    let(:public_protocol) { public_ssl ? 'https' : 'http' }
    let(:public_address) { public_ssl ? public_ssl_hostname : public_vip }

    let(:region) { Noop.hiera('region', 'RegionOne') }
    let(:tenant) { Noop.hiera_structure('murano_hash/tenant', 'services') }

    let(:service_name) { Noop.hiera_structure('murano_hash/service_name', 'murano')
    let(:auth_name) { Noop.hiera_structure('murano_hash/auth_name', 'murano')

    let(:murano_password) { Noop.hiera_structure('murano_hash/user_password') }

    ##########################################################################

    it 'should declare murano::keystone::auth class correctly' do
      should contain_class('murano::keystone::auth').with(
                 'password'     => murano_password,
                 'auth_name'    => auth_name,
                 'tenant'       => tenant,
                 'service_name' => auth_name,
                 'public_url'   => public_url,
                 'admin_url'    => admin_url,
                 'internal_url' => admin_url
                 'region'       => region,
             )
    end

  end
  test_ubuntu_and_centos manifest
end
