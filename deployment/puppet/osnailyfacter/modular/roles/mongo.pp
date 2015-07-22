notice('MODULAR: mongo.pp')

prepare_network_config(hiera('network_scheme', {}))
$bind_address      = get_network_role_property('mongo/db', 'ipaddr')
$use_syslog        = hiera('use_syslog', true)
$debug             = hiera('debug', false)
$roles             = hiera('roles')
$replset_name      = 'ceilometer'
$mongodb_port      = hiera('mongodb_port', '27017')

####################################################################
firewall {'120 mongodb':
  port   => $mongodb_port,
  proto  => 'tcp',
  action => 'accept',
} ->

class { 'openstack::mongo_secondary':
  mongodb_bind_address => [ '127.0.0.1', $bind_address ],
  mongodb_port         => $mongodb_port,
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
