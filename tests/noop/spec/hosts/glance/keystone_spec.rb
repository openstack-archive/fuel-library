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
manifest = 'glance/keystone.pp'

describe manifest do
  shared_examples 'catalog' do

    internal_protocol = 'http'
    internal_address = Noop.hiera('management_vip')
    admin_protocol = 'http'
    admin_address = internal_address

    if Noop.hiera_structure('use_ssl', false)
      public_protocol   = 'https'
      public_address    = Noop.hiera_structure('use_ssl/glance_public_hostname')
      internal_protocol = 'https'
      internal_address  = Noop.hiera_structure('use_ssl/glance_internal_hostname')
      admin_protocol    = 'https'
      admin_address     = Noop.hiera_structure('use_ssl/glance_admin_hostname')
    elsif Noop.hiera_structure('public_ssl/services')
      public_address  = Noop.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_address  = Noop.hiera('public_vip')
      public_protocol = 'http'
    end

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
  end
  test_ubuntu_and_centos manifest
end
