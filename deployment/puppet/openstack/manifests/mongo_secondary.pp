# == Class: openstack::mongo_secondary

class openstack::mongo_secondary (
  $auth                       = true,
  $ceilometer_database        = "ceilometer",
  $ceilometer_user            = "ceilometer",
  $ceilometer_metering_secret = undef,
  $ceilometer_db_password     = "ceilometer",
  $ceilometer_metering_secret = "ceilometer",
  $mongodb_bind_address       = ['127.0.0.1'],
  $mongodb_port               = 27017,
  $use_syslog                 = true,
  $verbose                    = false,
  $debug                      = false,
  $logappend                  = true,
  $journal                    = true,
  $replset_name               = undef,
  $keyfile                    = '/etc/mongodb.key',
  $oplog_size                 = '10240',
  $fork                       = false,
  $directoryperdb             = true,
  $profile                    = "1",
) {

  if $verbose {
    $verbositylevel = "vv"
  } else {
    $verbositylevel = "v"
  }

  if $use_syslog {
    $logpath = false
  } else {
    # undef to use defaults
    $logpath = undef
  }

  notify {"MongoDB params: $mongodb_bind_address": } ->

  class {'::mongodb::client':
  } ->

  class {'::mongodb::server':
    port           => $mongodb_port,
    verbose        => $verbose,
    syslog         => $use_syslog,
    logpath        => $logpath,
    logappend      => $logappend,
    journal        => $journal,
    bind_ip        => $mongodb_bind_address,
    auth           => $auth,
    replset        => $replset_name,
    keyfile        => $keyfile,
    directoryperdb => $directoryperdb,
    fork           => $fork,
    profile        => $profile,
  }
}
