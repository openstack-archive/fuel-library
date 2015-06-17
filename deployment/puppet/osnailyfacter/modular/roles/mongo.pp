notice('MODULAR: mongo.pp')

$use_syslog       = hiera('use_syslog', true)
$debug            = hiera('debug', false)
$internal_address = hiera('internal_address')
$nodes_hash       = hiera('nodes', {})
$roles            = node_roles($nodes_hash, hiera('uid'))
$replset_name     = 'ceilometer'

####################################################################
firewall {'120 mongodb':
  port   => $mongodb_port,
  proto  => 'tcp',
  action => 'accept',
} ->

class { 'openstack::mongo_secondary':
  mongodb_bind_address => [ '127.0.0.1', $internal_address ],
  use_syslog           => $use_syslog,
  mongo_version        => '2.6.10',
  debug                => $debug,
  replset_name         => $replset_name,
}

if !(member($roles, 'controller') or member($roles, 'primary-controller')) {
  sysctl::value { 'net.ipv4.tcp_keepalive_time':
    value => '300',
  }
}
