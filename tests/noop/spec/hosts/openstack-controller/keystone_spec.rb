# ROLE: primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for nova auth' do
      contain_class('nova::keystone::auth')
    end

    public_vip           = Noop.hiera('public_vip')
    internal_protocol    = 'http'
    internal_address     = Noop.hiera('management_vip')
    admin_protocol       = 'http'
    admin_address        = internal_address
    public_ssl           = Noop.hiera_structure('public_ssl/services')
    tenant               = Noop.hiera_structure('nova/tenant', 'services')

    if Noop.hiera_structure('use_ssl')
      public_protocol   = 'https'
      public_address    = Noop.hiera_structure('use_ssl/nova_public_hostname')
      internal_protocol = 'https'
      internal_address  = Noop.hiera_structure('use_ssl/nova_internal_hostname')
      admin_protocol    = 'https'
      admin_address     = Noop.hiera_structure('use_ssl/nova_admin_hostname')
    elsif public_ssl
      public_protocol = 'https'
      public_address  = Noop.hiera_structure('public_ssl/hostname')
    else
      public_protocol = 'http'
      public_address  = public_vip
    end

    compute_port    = '8774'
    public_base_url = "#{public_protocol}://#{public_address}:#{compute_port}"
    internal_base_url = "#{internal_protocol}://#{internal_address}:#{compute_port}"
    admin_base_url  = "#{admin_protocol}://#{admin_address}:#{compute_port}"

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[nova::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[nova::keystone::auth]")
    end

    it 'class nova::keystone::auth should  contain correct *_url' do
      should contain_class('nova::keystone::auth').with(
        'public_url'            => "#{public_base_url}/v2.1",
        'internal_url'          => "#{internal_base_url}/v2.1",
        'admin_url'             => "#{admin_base_url}/v2.1",
        'tenant'                => tenant,
        'configure_endpoint_v3' => false,
      )
    end

    it 'should contain legacy nova endpoint' do
      should contain_keystone__resource__service_identity('nova_legacy').with(
        'configure_user'      => false,
        'configure_user_role' => false,
        'service_type'        => 'compute_legacy',
        'service_description' => 'Openstack Compute Legacy Service',
        'service_name'        => 'compute_legacy',
        'public_url'          => "#{public_base_url}/v2/%(tenant_id)s",
        'internal_url'        => "#{internal_base_url}/v2/%(tenant_id)s",
        'admin_url'           => "#{admin_base_url}/v2/%(tenant_id)s",
        'tenant'              => tenant,
      )
    end
  end

  test_ubuntu_and_centos manifest
end
