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
manifest = 'openstack-haproxy/openstack-haproxy-neutron.pp'

describe manifest do
  shared_examples 'catalog' do

    neutron_nodes = Noop.hiera_hash('neutron_nodes')

    let(:neutron_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', neutron_nodes, 'heat/api'
    end

    let(:ipaddresses) do
      neutron_address_map.values
    end

    let(:server_names) do
      neutron_address_map.keys
    end

    use_neutron = Noop.hiera('use_neutron', false)

    if use_neutron and !Noop.hiera('external_lb', false)
      it "should properly configure neutron haproxy based on ssl" do
        public_ssl_neutron = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('neutron').with(
          'order'                  => '085',
          'ipaddresses'            => ipaddresses,
          'server_names'           => server_names,
          'listen_port'            => 9696,
          'public'                 => true,
          'public_ssl'             => public_ssl_neutron,
          'haproxy_config_options' => {
            'option'       => ['httpchk', 'httplog', 'httpclose'],
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',

        )
      end
    end
  end

  test_ubuntu_and_centos manifest
end
