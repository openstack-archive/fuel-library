# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# SKIP_HIERA: neut_vxlan_dvr.murano.sahara-primary-controller FIXME
# SKIP_HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl FIXME

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-murano.pp'

describe manifest do
  shared_examples 'catalog' do

    murano_nodes = Noop.hiera_hash('murano_nodes')

    let(:murano_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', murano_nodes, 'heat/api'
    end

    let(:ipaddresses) do
      murano_address_map.values
    end

    let(:server_names) do
      murano_address_map.keys
    end

    use_murano = Noop.hiera_structure('murano/enabled', false)
    use_cfapi_murano = Noop.hiera_structure('murano-cfapi/enabled', false)

    if use_murano and !Noop.hiera('external_lb', false)
      it "should properly configure murano haproxy based on ssl" do
        public_ssl_murano = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('murano-api').with(
          'order'                  => '190',
          'ipaddresses'            => ipaddresses,
          'server_names'           => server_names,
          'listen_port'            => 8082,
          'public'                 => true,
          'public_ssl'             => public_ssl_murano,
          'require_service'        => 'murano_api',
          'haproxy_config_options' => {
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end

      if use_cfapi_murano
        it "should properly configure murano-cfapi haproxy based on ssl" do
          public_ssl_murano = Noop.hiera_structure('public_ssl/services', false)
          should contain_openstack__ha__haproxy_service('murano-cfapi').with(
            'order'                  => '192',
            'ipaddresses'            => ipaddresses,
            'server_names'           => server_names,
            'listen_port'            => 8083,
            'public'                 => true,
            'public_ssl'             => public_ssl_murano,
            'require_service'        => 'murano_cfapi',
            'haproxy_config_options' => {
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },
          )
        end
      end

      it "should properly configure murano rabbitmq haproxy" do
        public_ssl_murano = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('murano_rabbitmq').with(
          'order'                  => '191',
          'ipaddresses'            => ipaddresses,
          'server_names'           => server_names,
          'listen_port'            => 55572,
          'internal'               => false,
          'haproxy_config_options' => {
            'option'         => ['tcpka'],
            'timeout client' => '48h',
            'timeout server' => '48h',
            'balance'        => 'roundrobin',
            'mode'           => 'tcp',
          },
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
