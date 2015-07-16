notice('MODULAR: mongo_primary.pp')

prepare_network_config(hiera('network_scheme', {}))
$bind_address     = get_network_role_property('mongo/db', 'ipaddr')
$use_syslog       = hiera('use_syslog', true)
$debug            = hiera('debug', false)
$ceilometer_hash  = hiera('ceilometer')
$nodes_hash       = hiera('nodes')
$roles            = hiera('roles')

####################################################################
if size(mongo_hosts($nodes_hash, 'array', 'mongo')) > 1 {
  $replset = 'ceilometer'
}
else {
  $replset = undef
}

class { 'openstack::mongo_primary':
  mongodb_bind_address        => [ '127.0.0.1', $bind_address ],
  ceilometer_metering_secret  => $ceilometer_hash['metering_secret'],
  ceilometer_db_password      => $ceilometer_hash['db_password'],
  ceilometer_replset_members  => mongo_hosts($nodes_hash, 'array', 'mongo'),
  replset                     => $replset,
  use_syslog                  => $use_syslog,
  debug                       => $debug,
}

if !(member($roles, 'controller') or member($roles, 'primary-controller')) {
  sysctl::value { 'net.ipv4.tcp_keepalive_time':
    value => '300',
  }
}
