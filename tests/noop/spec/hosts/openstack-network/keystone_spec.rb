require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    internal_protocol = 'http'
    internal_address  = task.hiera('management_vip')
    admin_protocol = internal_protocol
    admin_address  = internal_address
    if task.hiera_structure('use_ssl', false)
      public_protocol = 'https'
      public_address  = task.hiera_structure('use_ssl/neutron_public_hostname')
      internal_protocol = 'https'
      internal_address  = task.hiera_structure('use_ssl/neutron_internal_hostname')
      admin_protocol = 'https'
      admin_address  = task.hiera_structure('use_ssl/neutron_admin_hostname')
    elsif task.hiera_structure('public_ssl/services', false)
      public_address  = task.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_protocol = 'http'
      public_address  = task.hiera('public_vip')
    end
    region              = task.hiera_structure('quantum_settings/region', 'RegionOne')
    password            = task.hiera_structure('quantum_settings/keystone/admin_password')
    auth_name           = task.hiera_structure('quantum_settings/auth_name', 'neutron')
    configure_endpoint  = task.hiera_structure('quantum_settings/configure_endpoint', true)
    configure_user      = task.hiera_structure('quantum_settings/configure_user', true)
    configure_user_role = task.hiera_structure('quantum_settings/configure_user_role', true)
    service_name        = task.hiera_structure('quantum_settings/service_name', 'neutron')
    tenant              = task.hiera_structure('quantum_settings/tenant', 'services')
    port                ='9696'
    public_url          = "#{public_protocol}://#{public_address}:#{port}"
    internal_url        = "#{internal_protocol}://#{internal_address}:#{port}"
    admin_url           = "#{admin_protocol}://#{admin_address}:#{port}"
    use_neutron         = task.hiera('use_neutron', false)

    if use_neutron

      it 'should have explicit ordering between LB classes and particular actions' do
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[neutron::keystone::auth]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[neutron::keystone::auth]")
      end
      it 'should declare neutron::keystone::auth class' do
        should contain_class('neutron::keystone::auth').with(
          'password'            => password,
          'auth_name'           => auth_name,
          'configure_endpoint'  => configure_endpoint,
          'configure_user'      => configure_user,
          'configure_user_role' => configure_user_role,
          'service_name'        => service_name,
          'public_url'          => public_url,
          'internal_url'        => internal_url,
          'admin_url'           => admin_url,
          'region'              => region,
          'tenant'              => tenant,
        )
      end
    end
  end

  test_ubuntu_and_centos manifest
end
