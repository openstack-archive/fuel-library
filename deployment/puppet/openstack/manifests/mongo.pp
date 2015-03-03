# == Class: openstack::mongo

class openstack::mongo (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = "ceilometer",
  $ceilometer_metering_secret   = "ceilometer",
  $mongodb_port                 = 27017,
  $mongodb_bind_address         = ['0.0.0.0'],
  $use_syslog                   = true,
  $verbose                      = false,
  $debug                        = false,
) {

  if $debug {
    $set_parameter = 'logLevel=2'
    $quiet         = false
  } else {
    $set_parameter = 'logLevel=0'
    $quiet         = true
  }

  class {'::mongodb::client':
  } ->

  class {'::mongodb::server':
    port          => $mongodb_port,
    verbose       => $verbose,
    use_syslog    => $use_syslog,
    bind_ip       => $mongodb_bind_address,
    auth          => true,
    set_parameter => $set_parameter,
    quiet         => $quiet,
  } ->

  mongodb::db { $ceilometer_database:
    user          => $ceilometer_user,
    password      => $ceilometer_db_password,
    roles         => ['readWrite', 'dbAdmin'],
    admin_username => 'admin',
    admin_password => $ceilometer_db_password,
    admin_database => 'admin',
  } ->

  mongodb::db { 'admin':
    user         => 'admin',
    password     => $ceilometer_db_password,
    roles        => [
      'userAdmin',
      'readWrite',
      'dbAdmin',
      'dbAdminAnyDatabase',
      'readAnyDatabase',
      'readWriteAnyDatabase',
      'userAdminAnyDatabase',
      'clusterAdmin',
      'clusterManager',
      'clusterMonitor',
      'hostManager',
      'root',
      'restore',
    ],
    admin_username => 'admin',
    admin_password => $ceilometer_db_password,
    admin_database => 'admin',
  }

}
