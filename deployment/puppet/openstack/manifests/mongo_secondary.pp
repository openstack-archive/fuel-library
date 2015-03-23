# == Class: openstack::mongo_secondary

class openstack::mongo_secondary (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = "ceilometer",
  $ceilometer_metering_secret   = "ceilometer",
  $mongodb_port                 = 27017,
  $mongodb_bind_address         = ['0.0.0.0'],
  $replset                      = undef,
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

  notify {"MongoDB params: $mongodb_bind_address": } ->

  class {'::mongodb::client':
  } ->
  class {'::mongodb::server':
    port          => $mongodb_port,
    verbose       => $verbose,
    use_syslog    => $use_syslog,
    bind_ip       => $mongodb_bind_address,
    replset       => $replset,
    auth          => true,
    keyfile       => '/etc/mongodb.key',
    set_parameter => $set_parameter,
    quiet         => $quiet,
  }
}
