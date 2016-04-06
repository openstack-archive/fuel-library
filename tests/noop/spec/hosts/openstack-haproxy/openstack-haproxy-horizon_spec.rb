# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-horizon.pp'

describe manifest do
  shared_examples 'catalog' do

    horizon_nodes = Noop.hiera_hash('horizon_nodes')
    public_ssl_hash = Noop.hiera_hash('public_ssl', {})
    ssl_hash = Noop.hiera_hash('use_ssl', {})
    public_ssl_horizon = Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'horizon','public','usage',false

    let(:horizon_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', horizon_nodes, 'heat/api'
    end

    let(:ipaddresses) do
      horizon_address_map.values
    end

    let(:server_names) do
      horizon_address_map.keys
    end

    unless Noop.hiera('external_lb', false)
      it "should properly configure horizon haproxy based on ssl" do
        if public_ssl_horizon
          # http horizon should redirect to ssl horizon
          should contain_openstack__ha__haproxy_service('horizon').with(
            'server_names'           => nil,
            'ipaddresses'            => nil,
            'haproxy_config_options' => {
              'redirect' => 'scheme https if !{ ssl_fc }'
            }
          )
          should_not contain_haproxy__balancermember('horizon')
          should contain_openstack__ha__haproxy_service('horizon-ssl').with(
            'order'                  => '017',
            'ipaddresses'            => ipaddresses,
            'server_names'           => server_names,
            'listen_port'            => 443,
            'balancermember_port'    => 80,
            'public_ssl'             => public_ssl_horizon,
            'haproxy_config_options' => {
              'option'      => ['forwardfor', 'httpchk', 'httpclose', 'httplog'],
              'stick-table' => 'type ip size 200k expire 30m',
              'stick'       => 'on src',
              'balance'     => 'source',
              'timeout'     => ['client 3h', 'server 3h'],
              'mode'        => 'http',
              'reqadd'      => 'X-Forwarded-Proto:\ https',
            },
            'balancermember_options' => 'weight 1 check'
          )
          should contain_haproxy__balancermember('horizon-ssl')
        else
          # http horizon only
          should contain_openstack__ha__haproxy_service('horizon').with(
            'ipaddresses'            => ipaddresses,
            'server_names'           => server_names,
            'haproxy_config_options' => {
              'balance' => 'source',
              'capture' => 'cookie vgnvisitor= len 32',
              'cookie'  => 'SERVERID insert indirect nocache',
              'mode'    => 'http',
              'option'  => [ 'forwardfor', 'httpchk', 'httpclose', 'httplog' ],
              'rspidel' => '^Set-cookie:\ IP=',
              'timeout' => [ 'client 3h', 'server 3h' ]
            }
          )
          should contain_haproxy__balancermember('horizon')
          should_not contain_openstack__ha__haproxy_service('horizon-ssl')
          should_not contain_haproxy__balancermember('horizon-ssl')
        end
      end
    end
  end

  test_ubuntu_and_centos manifest
end
