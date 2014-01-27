# == Class: openstack::mongo_secondary

class openstack::mongo_secondary (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = $ceilometer_hash[db_password],
  $ceilometer_metering_secret   = "ceilometer",
  $mongodb_port                 = 27017,
  $mongodb_bind_addreess        = ['0.0.0.0'],
) {

  class {'::mongodb::client':
  } ->
  class {'::mongodb::server':
    port    => $mongodb_port,
    verbose => true,
    bind_ip => $mongodb_bind_addreess,
    replset => 'ceilometer',
    auth => true,
    keyfile => '/etc/mongodb.key',
  }
}
# vim: set ts=2 sw=2 et :
