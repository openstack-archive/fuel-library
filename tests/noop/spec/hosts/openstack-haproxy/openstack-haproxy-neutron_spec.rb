# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu

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
