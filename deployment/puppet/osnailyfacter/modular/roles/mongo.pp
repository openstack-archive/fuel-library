notice('MODULAR: mongo.pp')

prepare_network_config(hiera_hash('network_scheme', {}))
$mongo_hash          = hiera_hash('mongo', {})
$mongodb_port        = hiera('mongodb_port', '27017')
$mongo_nodes         = get_nodes_hash_by_roles(hiera_hash('network_metadata'), hiera('mongo_roles'))
$mongo_address_map   = get_node_to_ipaddr_map_by_network_role($mongo_nodes, 'mongo/db')
$mongo_hosts         = suffix(values($mongo_address_map), ":${mongodb_port}")
$bind_address        = get_network_role_property('mongo/db', 'ipaddr')
$use_syslog          = hiera('use_syslog', true)
$debug               = pick($mongo_hash['debug'], hiera('debug', false))
$ceilometer_hash     = hiera_hash('ceilometer_hash')
$roles               = hiera('roles')
$replset_name        = 'ceilometer'
$keyfile             = '/etc/mongodb.key'
$astute_keyfile      = '/var/lib/astute/mongodb/mongodb.key'
$ceilometer_database = pick($mongo_hash['ceilometer_database'], 'ceilometer')

if $debug {
  $verbositylevel = "vv"
} else {
  $verbositylevel = "v"
}

if $use_syslog {
  $logpath = false
} else {
  # undef to use defaults
  $logpath = undef
}

file { $keyfile:
  content => file($astute_keyfile),
  owner   => 'mongodb',
  mode    => '0600',
  require => Package['mongodb_server'],
  before  => Service['mongodb'],
}

class {'::mongodb::globals':
  version => '2.6.10',
} ->

class {'::mongodb::client': } ->

class {'::mongodb::server':
  package_ensure  => true,
  port            => $mongodb_port,
  verbose         => pick($mongo_hash['verbose'], false),
  verbositylevel  => $verbositylevel,
  syslog          => $use_syslog,
  logpath         => $logpath,
  journal         => pick($mongo_hash['journal'], true),
  bind_ip         => [ '127.0.0.1', $bind_address ],
  auth            => true,
  replset         => $replset_name,
  keyfile         => $keyfile,
  directoryperdb  => pick($mongo_hash['directoryperdb'], true),
  fork            => pick($mongo_hash['fork'], false),
  profile         => pick($mongo_hash['profile'], '1'),
  oplog_size      => pick($mongo_hash['oplog_size'], '10240'),
  dbpath          => pick($mongo_hash['dbpath'], '/var/lib/mongo/mongodb'),
  create_admin    => true,
  admin_password  => $ceilometer_hash['db_password'],
  store_creds     => true,
  replset_members => $mongo_hosts,
} ->

mongodb::db { $ceilometer_database:
  user           => pick($mongo_hash['ceilometer_user'], 'ceilometer'),
  password       => $ceilometer_hash['db_password'],
  roles          => [ 'readWrite', 'dbAdmin' ],
}

if ! roles_include(['controller', 'primary-controller']) {
  sysctl::value { 'net.ipv4.tcp_keepalive_time':
    value => '300',
  }
}
