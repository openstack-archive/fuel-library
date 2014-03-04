# == Class: openstack::mongo_primary

class openstack::mongo_primary (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = $ceilometer_hash[db_password],
  $ceilometer_metering_secret   = "ceilometer",
  $ceilometer_replset_members   = ['mongo2', mongo3],
) {

  notify {"mongodb primary start" : }->
  class {'::mongodb::client':
  } ->
  class {'::mongodb::server':
    port    => 27017,
    verbose => true,
    bind_ip => ['0.0.0.0'],
    replset => 'ceilometer',
    auth    => true,
    keyfile => '/etc/mongodb.key'
  } ->

  class {'::mongodb::replset':
    replset_setup   => true,
    replset_members => $ceilometer_replset_members,
  } ->

  mongodb::db { $ceilometer_database:
    user          => $ceilometer_user,
    password      => $ceilometer_db_password,
  } ->
  mongodb::db { 'admin':
    user         => 'admin',
    password     => $ceilometer_db_password,
    roles        => ['userAdmin','readWrite', 'dbAdmin', 'dbAdminAnyDatabase', 'readAnyDatabase', readWriteAnyDatabase],
  } ->
  notify {"mongodb primary finished": } ->
  notify {"mongo: $ceilometer_db_password": }

}
# vim: set ts=2 sw=2 et :

