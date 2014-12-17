import '../common/globals.pp'

class { 'openstack::mongo_primary':
  mongodb_bind_address        => [ '127.0.0.1', $internal_address ],
  ceilometer_metering_secret  => $ceilometer_hash['metering_secret'],
  ceilometer_db_password      => $ceilometer_hash['db_password'],
  ceilometer_replset_members  => mongo_hosts($nodes_hash, 'array', 'mongo'),
  use_syslog                  => $use_syslog,
  debug                       => $debug,
}
