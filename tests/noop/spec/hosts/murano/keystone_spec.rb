require 'spec_helper'
require 'shared-examples'
manifest = 'murano/keystone.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:service_endpoint) do
      Noop.hiera 'service_endpoint'
    end

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:public_address) do
      Noop.puppet_function 'prepare_network_config', network_scheme
      Noop.puppet_function 'get_network_role_property', 'ex', 'ipaddr'
    end

    let(:public_ssl) do
      Noop.hiera_structure('public_ssl/services')
    end

    let(:api_bind_port) do
      '8082'
    end

    let(:admin_url) do
      "http://#{service_endpoint}:#{api_bind_port}"
    end

    let(:public_url) do
      api_bind_port   = '8082'
      if public_ssl
        public_protocol = 'https'
        keystone_host = Noop.hiera_structure('public_ssl/hostname')
      else
        public_protocol = 'http'
        keystone_host = public_address
      end
      "#{public_protocol}://#{keystone_host}:#{api_bind_port}"
    end

    let(:region) do
      Noop.hiera('region', 'RegionOne')
    end

    let(:tenant) do
      Noop.hiera_structure('murano_hash/tenant', 'services')
    end

    let(:murano_password) do
      Noop.hiera_structure('murano_hash/user_password')
    end

    ##########################################################################

    it 'should declare murano::keystone::auth class correctly' do
      should contain_class('murano::keystone::auth').with(
                 'password'     => murano_password,
                 'service_type' => 'application_catalog',
                 'region'       => region,
                 'tenant'       => tenant,
                 'public_url'   => public_url,
                 'admin_url'    => admin_url,
                 'internal_url' => admin_url
             )
    end

  end
  test_ubuntu_and_centos manifest
end
