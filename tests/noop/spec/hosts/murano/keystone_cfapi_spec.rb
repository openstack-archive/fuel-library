require 'spec_helper'
require 'shared-examples'
manifest = 'murano/keystone_cfapi.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:service_endpoint) { task.hiera 'service_endpoint' }
    let(:network_scheme) { task.hiera_hash 'network_scheme' }
    api_bind_port = '8083'

    internal_protocol = 'http'
    internal_address = task.hiera('service_endpoint')
    admin_protocol = 'http'
    admin_address = internal_address

    if task.hiera_structure('use_ssl', false)
      public_protocol = 'https'
      public_address = task.hiera_structure('use_ssl/murano_public_hostname')
      internal_protocol = 'https'
      internal_address = task.hiera_structure('use_ssl/murano_internal_hostname')
      admin_protocol = 'https'
      admin_address = task.hiera_structure('use_ssl/murano_admin_hostname')
    elsif task.hiera_structure('public_ssl/services')
      public_protocol = 'https'
      public_address = task.hiera_structure('public_ssl/hostname')
    else
      public_protocol = 'http'
      public_address = task.hiera 'public_vip'
    end
    public_url = "#{public_protocol}://#{public_address}:#{api_bind_port}"
    internal_url = "#{internal_protocol}://#{internal_address}:#{api_bind_port}"
    admin_url = "#{admin_protocol}://#{admin_address}:#{api_bind_port}"

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[murano::keystone::cfapi_auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[murano::keystone::cfapi_auth]")
    end

    let(:region) { task.hiera('region', 'RegionOne') }
    let(:tenant) { task.hiera_structure('murano_hash/tenant', 'services') }

    let(:murano_password) { task.hiera_structure('murano_hash/user_password') }

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
