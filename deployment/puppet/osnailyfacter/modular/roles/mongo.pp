notice('MODULAR: mongo.pp')

prepare_network_config(hiera_hash('network_scheme', {}))
$mongo_hash        = hiera_hash('mongo', {})
$mongo_nodes       = get_nodes_hash_by_roles(hiera_hash('network_metadata'), hiera('mongo_roles'))
$mongo_address_map = get_node_to_ipaddr_map_by_network_role($mongo_nodes, 'mongo/db')
$bind_address      = get_network_role_property('mongo/db', 'ipaddr')
$use_syslog        = hiera('use_syslog', true)
$debug             = pick($mongo_hash['debug'], hiera('debug', false))
$ceilometer_hash   = hiera_hash('ceilometer_hash')
$roles             = hiera('roles')
$replset_name      = 'ceilometer'
$mongodb_port      = hiera('mongodb_port', '27017')

if $mongo_hash['oplog_size'] {
  $oplog_size = $mongo_hash['oplog_size']
} else {
  # undef to use defaults
  $oplog_size = undef
}

####################################################################
class { 'openstack::mongo':
  mongodb_bind_address       => [ '127.0.0.1', $bind_address ],
  mongodb_port               => $mongodb_port,
  ceilometer_metering_secret => $ceilometer_hash['metering_secret'],
  ceilometer_db_password     => $ceilometer_hash['db_password'],
  ceilometer_replset_members => values($mongo_address_map),
  replset_name               => $replset_name,
  mongo_version              => '2.6.10',
  use_syslog                 => $use_syslog,
  debug                      => $debug,
  oplog_size                 => $oplog_size,
}

if ! roles_include(['controller', 'primary-controller']) {
  sysctl::value { 'net.ipv4.tcp_keepalive_time':
    value => '300',
  }
}
