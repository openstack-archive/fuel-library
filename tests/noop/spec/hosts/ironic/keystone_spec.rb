# ROLE: primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    if ironic_enabled
      public_vip    = Noop.hiera('public_vip')
      admin_address = Noop.hiera('management_vip')
      let(:public_ssl_hash) { Noop.hiera_hash('public_ssl') }
      let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }
      let(:public_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'ironic','public','protocol','http' }
      let(:public_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'ironic','public','hostname', public_vip }
      let(:internal_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'ironic','internal','protocol','http' }
      let(:internal_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'ironic','internal','hostname', public_vip }
      let(:admin_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'ironic','admin','protocol','http' }
      let(:admin_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'ironic','admin','hostname', public_vip }
      let(:public_url) { "#{public_protocol}://#{public_address}:6385" }
      let(:admin_url) { "#{admin_protocol}://#{admin_address}:6385" }
      let(:internal_url) { "#{internal_protocol}://#{internal_address}:6385" }

      auth_name           = Noop.hiera_structure('ironic/auth_name', 'ironic')
      password            = Noop.hiera_structure('ironic/user_password')
      configure_endpoint  = Noop.hiera_structure('ironic/configure_endpoint', true)
      configure_user      = Noop.hiera_structure('ironic/configure_user', true)
      configure_user_role = Noop.hiera_structure('ironic/configure_user_role', true)
      region              = Noop.hiera_structure('ironic/region', 'RegionOne')
      tenant              = Noop.hiera_structure('ironic/tenant', 'services')
      service_name        = Noop.hiera_structure('ironic/service_name', 'ironic')

      it 'should have explicit ordering between LB classes and particular actions' do
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[ironic::keystone::auth]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[ironic::keystone::auth]")
      end

      it 'should declare ironic::keystone::auth class correctly' do
        should contain_class('ironic::keystone::auth').with(
          'auth_name'           => auth_name,
          'password'            => password,
          'configure_endpoint'  => configure_endpoint,
          'configure_user'      => configure_user,
          'configure_user_role' => configure_user_role,
          'service_name'        => service_name,
          'public_url'          => public_url,
          'admin_url'           => admin_url,
          'internal_url'        => internal_url,
          'region'              => region,
          'tenant'              => tenant,
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
