#
# parameters that may need to be added
# $state_path = /opt/stack/data/cinder
# $osapi_volume_extension = cinder.api.openstack.volume.contrib.standard_extensions
# $root_helper = sudo /usr/local/bin/cinder-rootwrap /etc/cinder/rootwrap.conf
# $use_syslog = Rather or not service should log to syslog. Optional.
# $syslog_log_facility = Facility for syslog, if used. Optional.
# $syslog_log_level = logging level for non verbose and non debug mode. Optional.

class cinder::base (
  $rabbit_password,
  $qpid_password,
  $sql_connection,
  $rpc_backend            = 'cinder.openstack.common.rpc.impl_kombu',
  $qpid_rpc_backend       = 'cinder.openstack.common.rpc.impl_qpid',
  $queue_provider         = 'rabbitmq',
  $rabbit_host            = false,
  $rabbit_hosts           = ['127.0.0.1'],
  $rabbit_port            = 5672,
  $rabbit_virtual_host    = '/',
  $rabbit_userid          = 'nova',
  $qpid_host              = false,
  $qpid_hosts             = ['127.0.0.1'],
  $qpid_port              = 5672,
  $qpid_userid            = 'nova',
  $package_ensure         = 'present',
  $verbose                = 'False',
  $debug                  = 'False',
  $use_syslog             = false,
  $syslog_log_facility    = "LOCAL3",
  $syslog_log_level = 'WARNING',
  $log_dir                = '/var/log/cinder',
) {

  include cinder::params

  if !defined(Package[$::cinder::params::qemuimg_package_name])
  {
    package {"$::cinder::params::qemuimg_package_name":}
  }

  package { 'python-cinder':
        ensure  => $package_ensure,
         }
  Package['cinder'] -> Cinder_config<||>
  Package['cinder'] -> Cinder_api_paste_ini<||>

  package { 'cinder':
    name => $::cinder::params::package_name,
    ensure => $package_ensure,
  }

  File {
    ensure  => present,
    owner   => 'cinder',
    group   => 'cinder',
    mode    => '0640',
    require => Package['cinder'],
  }

if $use_syslog and !$debug =~ /(?i)(true|yes)/ {
  cinder_config {
    'DEFAULT/log_config': value => "/etc/cinder/logging.conf";
    'DEFAULT/log_file':   ensure=> absent;
    'DEFAULT/log_dir':    ensure=> absent;
    'DEFAULT/logfile':   ensure=> absent;
    'DEFAULT/logdir':    ensure=> absent;
    'DEFAULT/use_stderr': ensure=> absent;
    'DEFAULT/use_syslog': value => true;
    'DEFAULT/syslog_log_facility': value =>  $syslog_log_facility;
  }
  file { "cinder-logging.conf":
    content => template('cinder/logging.conf.erb'),
    path => "/etc/cinder/logging.conf",
    require => File[$::cinder::params::cinder_conf],
  }
}
else {
  cinder_config {
    'DEFAULT/log_config': ensure=> absent;
    'DEFAULT/use_syslog': ensure=> absent;
    'DEFAULT/syslog_log_facility': ensure=> absent;
    'DEFAULT/use_stderr': ensure=> absent;
    'DEFAULT/logdir':value=> $log_dir;
    'DEFAULT/logging_context_format_string':
     value => '%(asctime)s %(levelname)s %(name)s [%(request_id)s %(user_id)s %(project_id)s] %(instance)s %(message)s';
    'DEFAULT/logging_default_format_string':
     value => '%(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s';
  }
  # might be used for stdout logging instead, if configured
  file { "cinder-logging.conf":
    content => template('cinder/logging.conf-nosyslog.erb'),
    path => "/etc/cinder/logging.conf",
    require => File[$::cinder::params::cinder_conf],
  }
}
  # We must notify services to apply new logging rules
  File['cinder-logging.conf'] ~> Service<| title == "$::cinder::params::api_service" |>
  File['cinder-logging.conf'] ~> Service<| title == "$::cinder::params::volume_service" |>
  File['cinder-logging.conf'] ~> Service<| title == "$::cinder::params::scheduler_service" |>

  file { $::cinder::params::cinder_conf: }
  file { $::cinder::params::cinder_paste_api_ini: }

  # Temporary fixes
  file { ['/var/log/cinder', '/var/lib/cinder']:
    ensure => directory,
    owner  => 'cinder',
    group  => 'cinder',
  }
  case $queue_provider {
    'rabbitmq': {
      if $rabbit_host
      {
        cinder_config {
        'DEFAULT/rabbit_host':         value => $rabbit_host;
        }
      }
      if $rabbit_hosts
      {
        cinder_config {
        'DEFAULT/rabbit_hosts':         value => $rabbit_hosts;
        }
      }
      cinder_config {
        'DEFAULT/rpc_backend':         value => $rpc_backend;
        'DEFAULT/rabbit_password':     value => $rabbit_password;
        'DEFAULT/rabbit_port':         value => $rabbit_port;
        'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
        'DEFAULT/rabbit_userid':       value => $rabbit_userid;
      }
    }
    'qpid': {
      if $qpid_host
      {
        cinder_config {
        'DEFAULT/qpid_hostname':           value => $qpid_host;
        }
      }
      if $qpid_hosts
      {
        cinder_config {
        'DEFAULT/qpid_hosts':         value => $qpid_hosts;
        }
      }
      cinder_config {
        'DEFAULT/rpc_backend':         value => $qpid_rpc_backend;
        'DEFAULT/qpid_password':       value => $qpid_password;
        'DEFAULT/qpid_port':           value => $qpid_port;
        'DEFAULT/qpid_username':         value => $qpid_userid;
      }
    }
  }

  cinder_config {
    'DEFAULT/sql_connection':      value => $sql_connection;
    'DEFAULT/debug':               value => $debug;
    'DEFAULT/verbose':             value => $verbose;
    'DEFAULT/api_paste_config':    value => '/etc/cinder/api-paste.ini';
  }
  exec { 'cinder-manage db_sync':
    command     => $::cinder::params::db_sync_command,
    path        => '/usr/bin',
    user        => 'cinder',
    refreshonly => true,
    logoutput   => 'on_failure',
    tries       => 10,
    try_sleep   => 3,
  }
  Cinder_config<||> -> Exec['cinder-manage db_sync']
  Nova_config<||> -> Exec['cinder-manage db_sync']
  Cinder_api_paste_ini<||> -> Exec['cinder-manage db_sync']
 Exec['cinder-manage db_sync'] -> Service<| title == $::cinder::params::api_service |>
 Exec['cinder-manage db_sync'] -> Service<| title == $::cinder::params::volume_service |>
 Exec['cinder-manage db_sync'] -> Service<| title == $::cinder::params::scheduler_service |>
}
