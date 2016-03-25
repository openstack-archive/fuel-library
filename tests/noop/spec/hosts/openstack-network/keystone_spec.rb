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
manifest = 'openstack-network/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    internal_protocol = 'http'
    internal_address  = Noop.hiera('management_vip')
    admin_protocol = internal_protocol
    admin_address  = internal_address
    if Noop.hiera_structure('use_ssl', false)
      public_protocol = 'https'
      public_address  = Noop.hiera_structure('use_ssl/neutron_public_hostname')
      internal_protocol = 'https'
      internal_address  = Noop.hiera_structure('use_ssl/neutron_internal_hostname')
      admin_protocol = 'https'
      admin_address  = Noop.hiera_structure('use_ssl/neutron_admin_hostname')
    elsif Noop.hiera_structure('public_ssl/services', false)
      public_address  = Noop.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_protocol = 'http'
      public_address  = Noop.hiera('public_vip')
    end
    region              = Noop.hiera_structure('quantum_settings/region', 'RegionOne')
    password            = Noop.hiera_structure('quantum_settings/keystone/admin_password')
    auth_name           = Noop.hiera_structure('quantum_settings/auth_name', 'neutron')
    configure_endpoint  = Noop.hiera_structure('quantum_settings/configure_endpoint', true)
    configure_user      = Noop.hiera_structure('quantum_settings/configure_user', true)
    configure_user_role = Noop.hiera_structure('quantum_settings/configure_user_role', true)
    service_name        = Noop.hiera_structure('quantum_settings/service_name', 'neutron')
    tenant              = Noop.hiera_structure('quantum_settings/tenant', 'services')
    port                ='9696'
    public_url          = "#{public_protocol}://#{public_address}:#{port}"
    internal_url        = "#{internal_protocol}://#{internal_address}:#{port}"
    admin_url           = "#{admin_protocol}://#{admin_address}:#{port}"
    use_neutron         = Noop.hiera('use_neutron', false)

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
