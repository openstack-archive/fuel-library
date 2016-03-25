# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml ubuntu
# RUN: neut_vlan.ironic.controller.yaml ubuntu
# RUN: neut_vlan.ironic.conductor.yaml ubuntu
# RUN: neut_vlan.compute.ssl.yaml ubuntu
# RUN: neut_vlan.compute.ssl.overridden.yaml ubuntu
# RUN: neut_vlan.compute.nossl.yaml ubuntu
# RUN: neut_vlan.cinder-block-device.compute.yaml ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml ubuntu
# RUN: neut_gre.generate_vms.yaml ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'swift/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for swift auth' do
      contain_class('swift::keystone::auth')
    end

    swift = Noop.hiera_hash('swift')
    configure_user = swift.fetch('configure_user', true)
    configure_user_role = swift.fetch('configure_user_role', true)

    if swift['management_vip']
      management_vip = swift['management_vip']
    else
      management_vip = Noop.hiera('management_vip')
    end

    if Noop.hiera_structure('use_ssl/swift_public', false)
      public_protocol = 'https'
      public_address  = Noop.hiera_structure('use_ssl/swift_public_hostname')
    elsif Noop.hiera_structure('public_ssl/services')
      public_address  = Noop.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    elsif swift['public_vip']
      public_protocol = 'http'
      public_address  = swift['public_vip']
    else
      public_address  = Noop.hiera('public_vip')
      public_protocol = 'http'
    end

    if Noop.hiera_structure('use_ssl/swift_internal', false)
      internal_protocol = 'https'
      internal_address  = Noop.hiera_structure('use_ssl/swift_internal_hostname')
    elsif swift['management_vip']
      internal_protocol = 'http'
      internal_address  = swift['management_vip']
    else
      internal_protocol = 'http'
      internal_address  = Noop.hiera('management_vip')
    end

    if Noop.hiera_structure('use_ssl/swift_admin', false)
      admin_protocol = 'https'
      admin_address  = Noop.hiera_structure('use_ssl/swift_admin_hostname')
    elsif swift['management_vip']
      admin_protocol = 'http'
      admin_address  = swift['management_vip']
    else
      admin_protocol = 'http'
      admin_address  = Noop.hiera('management_vip')
    end

    public_url          = "#{public_protocol}://#{public_address}:8080/v1/AUTH_%(tenant_id)s"
    internal_url        = "#{internal_protocol}://#{internal_address}:8080/v1/AUTH_%(tenant_id)s"
    admin_url           = "#{admin_protocol}://#{admin_address}:8080/v1/AUTH_%(tenant_id)s"

    public_url_s3       = "#{public_protocol}://#{public_address}:8080"
    internal_url_s3     = "#{internal_protocol}://#{internal_address}:8080"
    admin_url_s3        = "#{admin_protocol}://#{admin_address}:8080"

    tenant              = Noop.hiera_structure('swift/tenant', 'services')

    it 'class swift::keystone::auth should contain correct *_url' do
      should contain_class('swift::keystone::auth').with('public_url' => public_url)
      should contain_class('swift::keystone::auth').with('admin_url' => admin_url)
      should contain_class('swift::keystone::auth').with('internal_url' => internal_url)
    end

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[swift::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[swift::keystone::auth]")
    end

    it 'class swift::keystone::auth should contain correct S3 endpoints' do
      should contain_class('swift::keystone::auth').with('public_url_s3' => public_url_s3)
      should contain_class('swift::keystone::auth').with('admin_url_s3' => admin_url_s3)
      should contain_class('swift::keystone::auth').with('internal_url_s3' => internal_url_s3)
    end

    it 'class swift::keystone::auth should contain tenant' do
      should contain_class('swift::keystone::auth').with('tenant' => tenant)
    end

    it 'class swift::keystone::auth should contain configure_user parameters' do
      should contain_class('swift::keystone::auth').with('configure_user' => configure_user)
      should contain_class('swift::keystone::auth').with('configure_user_role' => configure_user_role)
    end

  end

  test_ubuntu_and_centos manifest
end
