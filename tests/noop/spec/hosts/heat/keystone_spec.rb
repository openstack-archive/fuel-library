# HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# HIERA: neut_vlan.ironic.controller
# HIERA: neut_vlan_l3ha.ceph.ceil-controller
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl

require 'spec_helper'
require 'shared-examples'
manifest = 'heat/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for heat auth' do
      contain_class('heat::keystone::auth').with(
        'trusts_delegated_roles' => [],
      )
    end
    heat = Noop.hiera_hash('heat')
    internal_protocol = 'http'
    internal_address = Noop.hiera('management_vip')
    admin_protocol = 'http'
    admin_address  = internal_address

    configure_user = heat.fetch('configure_user', true)
    configure_user_role = heat.fetch('configure_user_role', true)

    if Noop.hiera_structure('use_ssl', false)
      public_protocol = 'https'
      public_address  = Noop.hiera_structure('use_ssl/heat_public_hostname')
      internal_protocol = 'https'
      internal_address = Noop.hiera_structure('use_ssl/heat_internal_hostname')
      admin_protocol = 'https'
      admin_address = Noop.hiera_structure('use_ssl/heat_admin_hostname')
    elsif Noop.hiera_structure('public_ssl/services')
      public_protocol = 'https'
      public_address  = Noop.hiera_structure('public_ssl/hostname')
    else
      public_address  = Noop.hiera('public_vip')
      public_protocol = 'http'
    end

    public_url          = "#{public_protocol}://#{public_address}:8004/v1/%(tenant_id)s"
    internal_url        = "#{internal_protocol}://#{internal_address}:8004/v1/%(tenant_id)s"
    admin_url           = "#{admin_protocol}://#{admin_address}:8004/v1/%(tenant_id)s"
    public_url_cfn      = "#{public_protocol}://#{public_address}:8000/v1"
    internal_url_cfn    = "#{internal_protocol}://#{internal_address}:8000/v1"
    admin_url_cfn       = "#{admin_protocol}://#{admin_address}:8000/v1"
    tenant              = Noop.hiera_structure 'heat/tenant', 'services'

    it 'class heat::keystone::auth should contain correct *_url' do
      should contain_class('heat::keystone::auth').with('public_url' => public_url)
      should contain_class('heat::keystone::auth').with('internal_url' => internal_url)
      should contain_class('heat::keystone::auth').with('admin_url' => admin_url)
    end

    it 'class heat::keystone::auth_cfn should contain correct *_url' do
      should contain_class('heat::keystone::auth_cfn').with('public_url' => public_url_cfn)
      should contain_class('heat::keystone::auth_cfn').with('internal_url' => internal_url_cfn)
      should contain_class('heat::keystone::auth_cfn').with('admin_url' => admin_url_cfn)
    end

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[heat::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[heat::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[heat::keystone::auth_cfn]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[heat::keystone::auth_cfn]")
    end

    it 'class heat::keystone::auth should contain tenant' do
      should contain_class('heat::keystone::auth').with('tenant' => tenant)
    end

    it 'class heat::keystone::auth_cfn should contain configure_user parameters' do
      should contain_class('heat::keystone::auth_cfn').with('configure_user' => configure_user)
      should contain_class('heat::keystone::auth_cfn').with('configure_user_role' => configure_user_role)
    end

    it 'class heat::keystone::auth should contain configure_user parameters' do
      should contain_class('heat::keystone::auth').with('configure_user' => configure_user)
      should contain_class('heat::keystone::auth').with('configure_user_role' => configure_user_role)
    end

  end

  test_ubuntu_and_centos manifest
end
