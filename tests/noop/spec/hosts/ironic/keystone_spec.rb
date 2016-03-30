# HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# HIERA: neut_vlan.ironic.controller
# HIERA: neut_vlan_l3ha.ceph.ceil-controller
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl

require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    if ironic_enabled
      public_vip    = Noop.hiera('public_vip')
      admin_address = Noop.hiera('management_vip')
      public_ssl    = Noop.hiera_structure('public_ssl/services')

      if public_ssl
        public_address  = Noop.hiera_structure('public_ssl/hostname')
        public_protocol = 'https'
      else
        public_address  = public_vip
        public_protocol = 'http'
      end

      auth_name           = Noop.hiera_structure('ironic/auth_name', 'ironic')
      password            = Noop.hiera_structure('ironic/user_password')
      configure_endpoint  = Noop.hiera_structure('ironic/configure_endpoint', true)
      configure_user      = Noop.hiera_structure('ironic/configure_user', true)
      configure_user_role = Noop.hiera_structure('ironic/configure_user_role', true)
      region              = Noop.hiera_structure('ironic/region', 'RegionOne')
      tenant              = Noop.hiera_structure('ironic/tenant', 'services')
      service_name        = Noop.hiera_structure('ironic/service_name', 'ironic')
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
