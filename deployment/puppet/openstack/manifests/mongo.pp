# == Class: openstack::mongo

class openstack::mongo (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_user_password     = $ceilometer_hash[user_password],
  $ceilometer_metering_secret   = "ceilometer",
) {

  class {'::mongodb::client':
  } ->
  class {'::mongodb::server':
    port    => 27017,
    verbose => true,
    bind_ip => ['0.0.0.0'],
    auth => true,
  }
  mongodb::db { $ceilometer_database:
    user          => $ceilometer_user,
    password      => $ceilometer_user_password,
  } ->
  mongodb::db { 'admin':
    user         => 'admin',
    password     => $ceilometer_user_password,
    roles        => ['userAdmin','readWrite', 'dbAdmin'],
  }

 notify {"mongo: $ceilometer_user_password": }

}
# vim: set ts=2 sw=2 et :
