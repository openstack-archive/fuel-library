require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for cinder auth' do
      contain_class('cinder::keystone::auth')
    end

    public_protocol = 'http'
    internal_protocol = 'http'
    internal_address = task.hiera 'management_vip'
    admin_protocol = 'http'
    admin_address = internal_address

    if task.hiera_structure('use_ssl', false)
      public_protocol = 'https'
      public_address = task.hiera_structure('use_ssl/cinder_public_hostname')
      internal_protocol = 'https'
      internal_address = task.hiera_structure('use_ssl/cinder_internal_hostname')
      admin_protocol = 'https'
      admin_address = task.hiera_structure('use_ssl/cinder_admin_hostname')
    elsif task.hiera_structure('public_ssl/services')
      public_address  = task.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_address  = task.hiera('public_vip')
    end

    public_url    = "#{public_protocol}://#{public_address}:8776/v1/%(tenant_id)s"
    internal_url  = "#{internal_protocol}://#{internal_address}:8776/v1/%(tenant_id)s"
    admin_url     = "#{admin_protocol}://#{admin_address}:8776/v1/%(tenant_id)s"
    public_url_v2 = "#{public_protocol}://#{public_address}:8776/v2/%(tenant_id)s"
    internal_url_v2 = "#{internal_protocol}://#{internal_address}:8776/v2/%(tenant_id)s"
    admin_url_v2  = "#{admin_protocol}://#{admin_address}:8776/v2/%(tenant_id)s"

    password = task.hiera_structure 'cinder/user_password'
    auth_name = task.hiera_structure 'cinder/auth_name', 'cinder'
    configure_endpoint = task.hiera_structure 'cinder/configure_endpoint', true
    configure_user = task.hiera_structure 'cinder/configure_user_role', true
    service_name = task.hiera_structure 'cinder/service_name', 'cinder'
    region = task.hiera_structure 'cinder/region', 'RegionOne'
    tenant = task.hiera_structure 'cinder/tenant', 'services'

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[cinder::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[cinder::keystone::auth]")
    end

    it 'should declare cinder::keystone::auth class with propper parameters' do
      should contain_class('cinder::keystone::auth').with(
        'password'           => password,
        'auth_name'          => auth_name,
        'configure_endpoint' => configure_endpoint,
        'configure_user'     => configure_user,
        'service_name'       => service_name,
        'public_url'         => public_url,
        'internal_url'       => internal_url,
        'admin_url'          => admin_url,
        'public_url_v2'      => public_url_v2,
        'internal_url_v2'    => internal_url_v2,
        'admin_url_v2'       => admin_url_v2,
        'region'             => region,
        'tenant'             => tenant,
      )
    end

  end #end of shared examples

  test_ubuntu_and_centos manifest
end
