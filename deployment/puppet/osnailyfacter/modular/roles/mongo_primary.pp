notice('MODULAR: mongo_primary.pp')

prepare_network_config(hiera('network_scheme', {}))
$mongo_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('mongo_nodes'), 'mongo/db')
$bind_address      = get_network_role_property('mongo/db', 'ipaddr')
$use_syslog        = hiera('use_syslog', true)
$debug             = hiera('debug', false)
$ceilometer_hash   = hiera('ceilometer')
$roles             = hiera('roles')
$replset_name      = 'ceilometer'
$mongodb_port      = hiera('mongodb_port', '27017')

####################################################################
firewall {'120 mongodb':
  port   => $mongodb_port,
  proto  => 'tcp',
  action => 'accept',
} ->

class { 'openstack::mongo_primary':
  mongodb_bind_address       => [ '127.0.0.1', $bind_address ],
  mongodb_port               => $mongodb_port,
  ceilometer_metering_secret => $ceilometer_hash['metering_secret'],
  ceilometer_db_password     => $ceilometer_hash['db_password'],
  ceilometer_replset_members => values($mongo_address_map),
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
