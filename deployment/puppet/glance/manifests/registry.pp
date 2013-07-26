#
# [use_syslog] Rather or not service should log to syslog. Optional.
#
class glance::registry(
  $keystone_password,
  $verbose           = 'False',
  $debug             = 'False',
  $bind_host         = '0.0.0.0',
  $bind_port         = '9191',
  $log_file          = '/var/log/glance/registry.log',
  $sql_connection    = 'sqlite:///var/lib/glance/glance.sqlite',
  $sql_idle_timeout  = '3600',
  $auth_type         = 'keystone',
  $auth_host         = '127.0.0.1',
  $auth_port         = '35357',
  $auth_protocol     = 'http',
  $keystone_tenant   = 'admin',
  $keystone_user     = 'admin',
  $enabled           = true,
  $use_syslog        = false,
  $syslog_log_facility = 'LOCAL2',
  $syslog_log_level  = 'WARNING',
) inherits glance {

File {
  ensure  => present,
  owner   => 'glance',
  group   => 'glance',
  mode    => '0640',
  notify  => Service['glance-registry'],
  require => Class['glance']
}

if $use_syslog and !$debug =~ /(?i)(true|yes)/ {
 glance_registry_config {
   'DEFAULT/log_config': value => "/etc/glance/logging.conf";
   'DEFAULT/log_file': ensure=> absent;
   'DEFAULT/log_dir': ensure=> absent;
   'DEFAULT/logfile':   ensure=> absent;
   'DEFAULT/logdir':    ensure=> absent;
   'DEFAULT/use_stderr': ensure=> absent;
   'DEFAULT/use_syslog': value => true;
   'DEFAULT/syslog_log_facility': value =>  $syslog_log_facility;
 }
 if !defined(File["glance-logging.conf"]) {
   file {"glance-logging.conf":
     content => template('glance/logging.conf.erb'),
     path => "/etc/glance/logging.conf",
   }
 }
} else {
 glance_registry_config {
   'DEFAULT/log_config':    ensure=> absent;
   'DEFAULT/use_syslog': ensure=> absent;
   'DEFAULT/syslog_log_facility': ensure=> absent;
   'DEFAULT/use_stderr': ensure=> absent;
   'DEFAULT/logging_context_format_string':
    value => '%(asctime)s %(levelname)s %(name)s [%(request_id)s %(user_id)s %(project_id)s] %(instance)s %(message)s';
   'DEFAULT/logging_default_format_string':
    value => '%(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s';
 }
 # might be used for stdout logging instead, if configured
 if !defined(File["glance-logging.conf"]) {
   file {"glance-logging.conf":
     content => template('glance/logging.conf-nosyslog.erb'),
     path => "/etc/glance/logging.conf",
   }
 }
}

  require 'keystone::python'

  validate_re($sql_connection, '(sqlite|mysql|posgres):\/\/(\S+:\S+@\S+\/\S+)?')

  Package['glance'] -> Glance_registry_config<||>
  Glance_registry_config<||> ~> Exec<| title == 'glance-manage db_sync' |>
  Glance_registry_config<||> ~> Service['glance-registry']

  if($sql_connection =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
    require 'mysql::python'
  } elsif($sql_connection =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

  } elsif($sql_connection =~ /sqlite:\/\//) {

  } else {
    fail("Invalid db connection ${sql_connection}")
  }

  # basic service config
  glance_registry_config {
    'DEFAULT/debug':     value => $debug;
    'DEFAULT/verbose':   value => $verbose;
    'DEFAULT/bind_host': value => $bind_host;
    'DEFAULT/bind_port': value => $bind_port;
    'DEFAULT/backlog': value => "4096";
    'DEFAULT/api_limit_max': value => "1000";
    'DEFAULT/limit_param_default': value => "25";
  }

  # db connection config
  glance_registry_config {
    'DEFAULT/sql_connection':   value => $sql_connection;
    'DEFAULT/sql_idle_timeout': value => $sql_idle_timeout;
  }

  # auth config
  glance_registry_config {
    'keystone_authtoken/auth_host':     value => $auth_host;
    'keystone_authtoken/auth_port':     value => $auth_port;
    'keystone_authtoken/auth_protocol': value => $auth_protocol;
  }

  # keystone config
  if $auth_type == 'keystone' {
    glance_registry_config {
      'paste_deploy/flavor':                  value => 'keystone';
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_user':        value => $keystone_user;
      'keystone_authtoken/admin_password':    value => $keystone_password;
      'keystone_authtoken/signing_dir':       value => '/tmp/keystone-signing-glance';
      'keystone_authtoken/signing_dirname':   value => '/tmp/keystone-signing-glance';
    }
  }

  file { ['/etc/glance/glance-registry.conf',
         ]:
  }

  if $enabled {

    Exec['glance-manage db_sync'] ~> Service['glance-registry']

    exec { 'glance-manage db_sync':
      command     => $::glance::params::db_sync_command,
      path        => '/usr/bin',
      user        => 'glance',
      refreshonly => true,
      logoutput   => on_failure,
      subscribe   => [Package['glance'], File['/etc/glance/glance-registry.conf']],
    }
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }
  Glance_registry_config <| |> -> Service['glance-registry']
  if $::osfamily=="Debian"
  {
 package {'glance-registry':
	 name => $::glance::params::registry_package_name,
 	 ensure => $package_ensure
 }
  File['/etc/glance/glance-registry.conf'] -> Glance_registry_config<||>
  Package['glance-registry']->Service['glance-registry']
  Glance_registry_config <| |> -> Package['glance-registry']
  }

  service { 'glance-registry':
    name       => $::glance::params::registry_service_name,
    ensure     => $service_ensure,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

}
