# == Class: openstack::mongo

class openstack::mongo (
  $auth                       = true,
  $ceilometer_database        = "ceilometer",
  $ceilometer_user            = "ceilometer",
  $ceilometer_db_password     = "ceilometer",
  $ceilometer_metering_secret = "ceilometer",
  $ceilometer_replset_members = ['127.0.0.1'],
  $mongodb_bind_address       = ['127.0.0.1'],
  $mongodb_port               = 27017,
  $use_syslog                 = true,
  $verbose                    = false,
  $debug                      = false,
  $logappend                  = true,
  $journal                    = true,
  $replset_name               = 'ceilometer',
  $keyfile                    = '/etc/mongodb.key',
  $key                        = undef,
  $oplog_size                 = '10240',
  $fork                       = false,
  $directoryperdb             = true,
  $profile                    = "1",
  $dbpath                     = '/var/lib/mongo/mongodb',
  $mongo_version              = undef,
) {

  if $debug {
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

  if $key {
    $key_content = $key
  } else {
    $key_content = file('/var/lib/astute/mongodb/mongodb.key')
  }

  class {'::mongodb::globals':
    version => $mongo_version,
  } ->

  notify {"MongoDB params: $mongodb_bind_address" :} ->

  class {'::mongodb::client':
  } ->

  firewall {'120 mongodb':
    port   => $mongodb_port,
    proto  => 'tcp',
    action => 'accept',
  } ->

  class {'::mongodb::server':
    package_ensure => true,
    port           => $mongodb_port,
    verbose        => $verbose,
    verbositylevel => $verbositylevel,
    syslog         => $use_syslog,
    logpath        => $logpath,
    logappend      => $logappend,
    journal        => $journal,
    bind_ip        => $mongodb_bind_address,
    auth           => $auth,
    replset        => $replset_name,
    keyfile        => $keyfile,
    key            => $key_content,
    directoryperdb => $directoryperdb,
    fork           => $fork,
    profile        => $profile,
    oplog_size     => $oplog_size,
    dbpath         => $dbpath,
    config_content => $config_content,
    create_admin   => true,
    admin_password => $ceilometer_db_password,
    store_creds    => true,
    replset_config => { $replset_name  => { ensure => present, members => $ceilometer_replset_members } }
  } ->

  notify {"mongodb configuring ceilometer database" :} ->

  mongodb::db { $ceilometer_database:
    user           => $ceilometer_user,
    password       => $ceilometer_db_password,
    roles          => [ 'readWrite', 'dbAdmin' ],
  } ->

  notify {"mongodb finished": }
}
