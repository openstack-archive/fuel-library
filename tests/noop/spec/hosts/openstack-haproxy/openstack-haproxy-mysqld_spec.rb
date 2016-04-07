# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-mysqld.pp'

describe manifest do
  shared_examples 'catalog' do
    mysql_hash = Noop.hiera_hash('mysql')
    use_mysql = Noop.puppet_function 'pick', mysql_hash['enabled'], true
    custom_mysql_setup_class = Noop.hiera('custom_mysql_setup_class', 'galera')
    external_lb = Noop.hiera('external_lb', false)

    if !external_lb and use_mysql and
      ['galera', 'percona', 'percona_packages'].include? custom_mysql_setup_class
      database_nodes = Noop.hiera_hash('database_nodes')
      db_address_map = Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role',
        database_nodes, 'mgmt/database'
      ipaddresses = Noop.hiera_array('mysqld_ipaddresses', db_address_map.values)
      server_names = Noop.hiera_array('mysqld_names', db_address_map.keys)
      public_virtual_ip = Noop.hiera('public_vip')
      internal_virtual_ip = Noop.hiera('database_vip', Noop.hiera('management_vip'))
      primary_controller = Noop.hiera('primary_controller')

      it 'should contain mysql ha class' do
        should contain_class('openstack::ha::mysqld').with(
          'internal_virtual_ip'   => internal_virtual_ip,
          'ipaddresses'           => ipaddresses,
          'public_virtual_ip'     => public_virtual_ip,
          'server_names'          => server_names,
          'is_primary_controller' => primary_controller,
        )
      end

      it 'should properly configure database haproxy' do
        should contain_openstack__ha__haproxy_service('mysqld').with(
          'order'                  => '110',
          'listen_port'            => 3306,
          'balancermember_port'    => 3307,
          'define_backups'         => true,
          'haproxy_config_options' => {
            'hash-type'      => 'consistent',
            'option'         => ['httpchk', 'tcplog','clitcpka','srvtcpka'],
            'balance'        => 'source',
            'mode'           => 'tcp',
            'timeout server' => '28801s',
            'timeout client' => '28801s'
          },
          'balancermember_options' =>
            'check port 49000 inter 20s fastinter 2s downinter 2s rise 3 fall 3',
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end