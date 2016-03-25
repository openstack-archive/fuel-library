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

    ec2_port         = '8773'
    ec2_public_url   = "#{public_protocol}://#{public_address}:#{ec2_port}/services/Cloud"
    ec2_internal_url = "#{internal_protocol}://#{internal_address}:#{ec2_port}/services/Cloud"
    ec2_admin_url    = "#{admin_protocol}://#{admin_address}:#{ec2_port}/services/Admin"

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[nova::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[nova::keystone::auth]")
    end

    it 'class nova::keystone::auth should  contain correct *_url' do
      should contain_class('nova::keystone::auth').with(
        'public_url'       => "#{public_base_url}/v2/%(tenant_id)s",
        'public_url_v3'    => "#{public_base_url}/v3",
        'internal_url'     => "#{internal_base_url}/v2/%(tenant_id)s",
        'internal_url_v3'  => "#{internal_base_url}/v3",
        'admin_url'        => "#{admin_base_url}/v2/%(tenant_id)s",
        'admin_url_v3'     => "#{admin_base_url}/v3",
        'ec2_public_url'   => ec2_public_url,
        'ec2_admin_url'    => ec2_admin_url,
        'ec2_internal_url' => ec2_internal_url,
        'tenant'           => tenant,
      )
    end
  end

  test_ubuntu_and_centos manifest
end
