notice('MODULAR: mongo_primary.pp')

$use_syslog       = hiera('use_syslog', true)
$debug            = hiera('debug', false)
$internal_address = hiera('internal_address')
$ceilometer_hash  = hiera('ceilometer')
$nodes_hash       = hiera('nodes')
$roles            = node_roles($nodes_hash, hiera('uid'))
$replset_name     = 'ceilometer'

####################################################################
firewall {'120 mongodb':
  port   => $mongodb_port,
  proto  => 'tcp',
  action => 'accept',
} ->

class { 'openstack::mongo_primary':
  mongodb_bind_address       => [ '127.0.0.1', $internal_address ],
  ceilometer_metering_secret => $ceilometer_hash['metering_secret'],
  ceilometer_db_password     => $ceilometer_hash['db_password'],
  ceilometer_replset_members => mongo_hosts($nodes_hash, 'array'),
  replset_name               => $replset_name,
  mongo_version              => '2.6.10',
  use_syslog                 => $use_syslog,
  debug                      => $debug,
}

if !(member($roles, 'controller') or member($roles, 'primary-controller')) {
  sysctl::value { 'net.ipv4.tcp_keepalive_time':
    value => '300',
  }
}
