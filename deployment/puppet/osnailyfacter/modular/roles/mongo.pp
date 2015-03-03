notice('MODULAR: mongo.pp')

$use_syslog       = hiera('use_syslog', true)
$debug            = hiera('debug', false)
$internal_address = hiera('internal_address')
$nodes_hash       = hiera('nodes', {})
$roles            = node_roles($nodes_hash, hiera('uid'))

####################################################################

class { 'openstack::mongo_secondary':
  mongodb_bind_address        => [ '127.0.0.1', $internal_address ],
  use_syslog                  => $use_syslog,
  debug                       => $debug,
  replset                     => 'ceilometer',
}

if !(member($roles, 'controller') or member($roles, 'primary-controller')) {
  sysctl::value { 'net.ipv4.tcp_keepalive_time':
    value => '300',
  }
}
