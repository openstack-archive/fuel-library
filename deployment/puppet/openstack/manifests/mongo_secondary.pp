# == Class: openstack::mongo_secondary

class openstack::mongo_secondary (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = $ceilometer_hash[db_password],
  $ceilometer_metering_secret   = "ceilometer",
) {

  class {'::mongodb::client':
  } ->
  class {'::mongodb::server':
    port    => 27017,
    verbose => true,
    bind_ip => ['0.0.0.0'],
    replset => 'ceilometer',
    auth    => true,
    keyfile => '/etc/mongodb.key',
  }
}
# vim: set ts=2 sw=2 et :
