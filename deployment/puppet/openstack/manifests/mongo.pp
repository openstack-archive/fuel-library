# == Class: openstack::mongo

class openstack::mongo (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = "ceilometer",
  $ceilometer_metering_secret   = "ceilometer",
  $mongodb_port                 = 27017,
  $mongodb_bind_address         = ['0.0.0.0'],
  $verbose                      = false,
  $use_syslog                   = true,
) {

#  notify {"MongoDB params: $ceilometer_user $ceilometer_database $ceilometer_db_password": }


  class {'::mongodb::client':
  } ->

  class {'::mongodb::server':
    port        => $mongodb_port,
    verbose     => $verbose,
    use_syslog  => $use_syslog,
    bind_ip     => $mongodb_bind_address,
    auth        => true,
  } ->

  mongodb::db { $ceilometer_database:
    user          => $ceilometer_user,
    password      => $ceilometer_db_password,
    roles         => ['readWrite', 'dbAdmin', 'dbOwner'],
  } ->

  mongodb::db { 'admin':
    user         => 'admin',
    password     => $ceilometer_db_password,
    roles        => ['userAdmin','readWrite', 'dbAdmin', 'dbAdminAnyDatabase', 'readAnyDatabase', 'readWriteAnyDatabase', 'userAdminAnyDatabase', 'clusterAdmin', 'clusterManager', 'clusterMonitor', 'hostManager', 'root' ],
  }

 #notify {"mongo: $ceilometer_db_password": }

}
