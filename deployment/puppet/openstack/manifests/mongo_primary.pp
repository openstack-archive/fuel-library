# == Class: openstack::mongo_primary

class openstack::mongo_primary (
  $ceilometer_database          = "ceilometer_database",
  $ceilometer_user              = "ceilometer_user",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = "ceilometer",
  $ceilometer_metering_secret   = "ceilometer",
  $ceilometer_replset_members   = ['mongo2', 'mongo3'],
  $mongodb_bind_address         = ['0.0.0.0'],
  $mongodb_port                 = 27017,
) {

  $replset_setup = size($ceilometer_replset_members) > 0
  notify {"MongoDB params: $mongodb_bind_address": }


  if $replset_setup {
    class {'::mongodb::client':
    } ->

    class {'::mongodb::server':
      port    => $mongodb_port,
      verbose => true,
      bind_ip => $mongodb_bind_address,
      replset => 'ceilometer',
      auth => true,
      keyfile => '/etc/mongodb.key'
    } ->

    class {'::mongodb::replset':
      replset_setup   => $replset_setup,
      replset_members => $ceilometer_replset_members,
    }
  } else {
    class {'::mongodb::client':
    } ->
    class {'::mongodb::server':
      port    => $mongodb_port,
      verbose => true,
      bind_ip => $mongodb_bind_address,
      auth => true,
    }
  }

  notify {"mongodb configuring databases": } ->

  mongodb::db { $ceilometer_database:
    user          => $ceilometer_user,
    password      => $ceilometer_db_password,
    roles         => ['readWrite', 'dbAdmin', 'dbOwner'],
  } ->

  mongodb::db { 'admin':
    user         => 'admin',
    password     => $ceilometer_db_password,
    roles        => ['userAdmin','readWrite', 'dbAdmin', 'dbAdminAnyDatabase', 'readAnyDatabase', 'readWriteAnyDatabase', 'userAdminAnyDatabase', 'clusterAdmin', 'clusterManager', 'clusterMonitor', 'hostManager', 'root' ],
  } ->

  notify {"mongodb primary finished": }
#  notify {"mongo: $ceilometer_db_password": }

}
# vim: set ts=2 sw=2 et :
