require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_enabled = task.hiera_structure 'ironic/enabled'

    if ironic_enabled
      public_vip    = task.hiera('public_vip')
      admin_address = task.hiera('management_vip')
      public_ssl    = task.hiera_structure('public_ssl/services')

      if public_ssl
        public_address  = task.hiera_structure('public_ssl/hostname')
        public_protocol = 'https'
      else
        public_address  = public_vip
        public_protocol = 'http'
      end

      auth_name           = task.hiera_structure('ironic/auth_name', 'ironic')
      password            = task.hiera_structure('ironic/user_password')
      configure_endpoint  = task.hiera_structure('ironic/configure_endpoint', true)
      configure_user      = task.hiera_structure('ironic/configure_user', true)
      configure_user_role = task.hiera_structure('ironic/configure_user_role', true)
      region              = task.hiera_structure('ironic/region', 'RegionOne')
      tenant              = task.hiera_structure('ironic/tenant', 'services')
      service_name        = task.hiera_structure('ironic/service_name', 'ironic')
      public_url          = "#{public_protocol}://#{public_address}:6385"
      admin_url           = "http://#{admin_address}:6385"

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
          'internal_url'        => admin_url,
          'region'              => region,
          'tenant'              => tenant,
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
