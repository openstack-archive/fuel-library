# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'glance/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    management_vip    = Noop.hiera('management_vip')
    ssl_hash          = Noop.hiera_structure('use_ssl', {})
    public_ssl_hash   = Noop.hiera_structure('public_ssl', {})
    internal_protocol = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance', 'internal','protocol','http'
    internal_address  = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance', 'internal','hostname', [management_vip]
    admin_protocol    = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance', 'admin', 'protocol','http'
    admin_address     = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance','admin', 'hostname', [management_vip]
    public_protocol   = Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'glance', 'public','protocol','http'
    public_address    = Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'glance','public', 'hostname', [Noop.hiera('public_vip')]

    glare_internal_protocol = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glare', 'internal','protocol','http'
    glare_internal_address  = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glare', 'internal','hostname', [management_vip]
    glare_admin_protocol    = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glare', 'admin', 'protocol','http'
    glare_admin_address     = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glare','admin', 'hostname', [management_vip]
    glare_public_protocol   = Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'glare', 'public','protocol','http'
    glare_public_address    = Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'glare','public', 'hostname', [Noop.hiera('public_vip')]

    auth_name           = Noop.hiera_structure('glance/auth_name', 'glance')
    password            = Noop.hiera_structure('glance/user_password')
    configure_endpoint  = Noop.hiera_structure('glance/configure_endpoint', true)
    configure_user      = Noop.hiera_structure('glance/configure_user', true)
    configure_user_role = Noop.hiera_structure('glance/configure_user_role', true)
    region              = Noop.hiera_structure('glance/region', 'RegionOne')
    tenant              = Noop.hiera_structure('glance/tenant', 'services')
    service_name        = Noop.hiera_structure('glance/service_name', 'glance')
    public_url          = "#{public_protocol}://#{public_address}:9292"
    internal_url        = "#{internal_protocol}://#{internal_address}:9292"
    admin_url           = "#{admin_protocol}://#{admin_address}:9292"

    glare_auth_name           = Noop.hiera_structure('glance_glare/auth_name', 'glance')
    glare_password            = Noop.hiera_structure('glance_glare/user_password')
    glare_configure_endpoint  = Noop.hiera_structure('glance_glare/configure_endpoint', true)
    glare_configure_user      = Noop.hiera_structure('glance_glare/configure_user', true)
    glare_configure_user_role = Noop.hiera_structure('glance_glare/configure_user_role', true)
    glare_region              = Noop.hiera_structure('glance_glare/region', 'RegionOne')
    glare_tenant              = Noop.hiera_structure('glance_glare/tenant', 'services')
    glare_service_name        = Noop.hiera_structure('glance_glare/service_name', 'glance')
    glare_public_url          = "#{glare_public_protocol}://#{glare_public_address}:9494"
    glare_internal_url        = "#{glare_internal_protocol}://#{glare_internal_address}:9494"
    glare_admin_url           = "#{glare_admin_protocol}://#{glare_admin_address}:9494"

    it 'should declare glance::keystone::auth class correctly' do
      should contain_class('glance::keystone::auth').with(
        'auth_name'           => auth_name,
        'password'            => password,
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

    it 'should declare glance::keystone::glare_auth class correctly' do
      should contain_class('glance::keystone::glare_auth').with(
        'auth_name'           => glare_auth_name,
        'password'            => glare_password,
        'configure_endpoint'  => glare_configure_endpoint,
        'configure_user'      => glare_configure_user,
        'configure_user_role' => glare_configure_user_role,
        'service_name'        => glare_service_name,
        'public_url'          => glare_public_url,
        'internal_url'        => glare_internal_url,
        'admin_url'           => glare_admin_url,
        'region'              => glare_region,
        'tenant'              => glare_tenant,
      )
    end

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[glance::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[glance::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[glance::keystone::glare_auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[glance::keystone::glare_auth]")
    end
  end
  test_ubuntu_and_centos manifest
end
