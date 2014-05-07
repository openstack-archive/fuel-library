# == Class: openstack::mongo_secondary

class openstack::mongo_secondary (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = "ceilometer",
  $ceilometer_metering_secret   = "ceilometer",
  $mongodb_port                 = 27017,
  $mongodb_bind_address         = ['0.0.0.0'],
  $use_syslog                   = true,
  $verbose                      = false,
) {

  notify {"MongoDB params: $mongodb_bind_address": } ->

  class {'::mongodb::client':
  } ->
  class {'::mongodb::server':
    port       => $mongodb_port,
    verbose    => $verbose,
    use_syslog => $use_syslog,
    bind_ip    => $mongodb_bind_address,
    replset    => 'ceilometer',
    auth       => true,
    keyfile    => '/etc/mongodb.key',
  }
}
