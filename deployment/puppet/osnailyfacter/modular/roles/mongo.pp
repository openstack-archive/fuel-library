notice('MODULAR: mongo.pp')

prepare_network_config(hiera('network_scheme', {}))
$bind_address     = get_network_role_property('mongo/db', 'ipaddr')
$use_syslog       = hiera('use_syslog', true)
$debug            = hiera('debug', false)
$nodes_hash       = hiera('nodes', {})
$roles            = node_roles($nodes_hash, hiera('uid'))

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
