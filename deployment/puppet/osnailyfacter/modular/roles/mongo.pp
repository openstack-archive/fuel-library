notice('MODULAR: mongo.pp')

prepare_network_config(hiera('network_scheme', {}))
$mongo_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('mongo_nodes'), 'mongo/db')
$bind_address      = get_network_role_property('mongo/db', 'ipaddr')
$use_syslog        = hiera('use_syslog', true)
$debug             = hiera('debug', false)
$roles             = hiera('roles')

####################################################################

class { 'openstack::mongo_secondary':
  mongodb_bind_address        => [ '127.0.0.1', $bind_address ],
  use_syslog                  => $use_syslog,
  debug                       => $debug,
  replset                     => 'ceilometer',
}

if !(member($roles, 'controller') or member($roles, 'primary-controller')) {
  sysctl::value { 'net.ipv4.tcp_keepalive_time':
    value => '300',
  }
}
