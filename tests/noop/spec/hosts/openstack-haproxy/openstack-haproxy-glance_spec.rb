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
manifest = 'openstack-haproxy/openstack-haproxy-glance.pp'

describe manifest do
  shared_examples 'catalog' do

    glance_nodes = Noop.hiera_hash('glance_nodes')

    let(:glance_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', glance_nodes, 'glance/api'
    end

    let(:ipaddresses) do
      glance_address_map.values
    end

    let(:server_names) do
      glance_address_map.keys
    end

    public_virtual_ip = Noop.hiera('public_vip')
    internal_virtual_ip = Noop.hiera('management_vip')
    public_ssl = Noop.hiera_structure('public_ssl/services')

    unless Noop.hiera('external_lb', false)
      it 'should configure glance haproxy' do
        should contain_openstack__ha__haproxy_service('glance-api').with(
          'order'                  => '080',
          'listen_port'            => 9292,
          'require_service'        => 'glance-api',

          # common parameters
          'internal_virtual_ip'    => internal_virtual_ip,
          'ipaddresses'            => ipaddresses,
          'public_virtual_ip'      => public_virtual_ip,
          'server_names'           => server_names,
          'public'                 => 'true',
          'public_ssl'             => public_ssl,
          'require_service'        => 'glance-api',
          'haproxy_config_options' => {
            'option'         => ['httpchk /versions', 'httplog', 'httpclose'],
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            'timeout server' => '11m',
           },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3'
        )

        should contain_openstack__ha__haproxy_service('glance-registry').with(
          'order'           => '090',
          'listen_port'     => 9191,
          'haproxy_config_options' => {
            'timeout server' => '11m',
           },
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

