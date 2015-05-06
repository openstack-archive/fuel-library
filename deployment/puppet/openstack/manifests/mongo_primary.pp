# == Class: openstack::mongo_primary

class openstack::mongo_primary (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = "ceilometer",
  $ceilometer_metering_secret   = "ceilometer",
  $ceilometer_replset_members   = ['mongo2', 'mongo3'],
  $mongodb_bind_address         = ['0.0.0.0'],
  $mongodb_port                 = 27017,
  $use_syslog                   = true,
  $verbose                      = false,
  $debug                        = false,
  $replset                      = 'ceilometer',
  $replset_setup                = true,
  $keyfile                      = '/etc/mongodb.key',
) {
  if $debug {
    $set_parameter = 'logLevel=2'
    $quiet         = false
  } else {
    $set_parameter = 'logLevel=0'
    $quiet         = true
  }

  notify {"MongoDB params: $mongodb_bind_address" :} ->

  class {'::mongodb::client':
  } ->

  class {'::mongodb::server':
    port          => $mongodb_port,
    verbose       => $verbose,
    use_syslog    => $use_syslog,
    bind_ip       => $mongodb_bind_address,
    auth          => true,
    replset       => $replset,
    keyfile       => $keyfile,
    set_parameter => $set_parameter,
    quiet         => $quiet,
  } ->

  class {'::mongodb::replset':
    replset_setup   => $replset_setup,
    replset_members => $ceilometer_replset_members,
    admin_password  => $ceilometer_db_password,
  } ->

  notify {"mongodb configuring databases" :} ->

  mongodb::db { $ceilometer_database:
    user          => $ceilometer_user,
    password      => $ceilometer_db_password,
    roles         => [ 'readWrite', 'dbAdmin' ],
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
  } ->

  notify {"mongodb primary finished": }

}
