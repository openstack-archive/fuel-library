#
#  [*use_syslog*]
#    (optional) Use syslog for logging.
#    Defaults to false.
#
#  [*syslog_log_facility*]
#    (optional) Syslog facility to receive log lines.
#    Defaults to LOG_LOCAL2.
#
#  [*log_file*]
#    (optional) Log file for glance-registry.
#    If set to boolean false, it will not log to any file.
#    Defaults to '/var/log/glance/registry.log'.
#
#  [*log_dir*]
#    (optional) directory to which glance logs are sent.
#    If set to boolean false, it will not log to any directory.
#    Defaults to '/var/log/glance'
#
class glance::registry(
  $keystone_password,
  $verbose             = false,
  $debug               = false,
  $bind_host           = '0.0.0.0',
  $bind_port           = '9191',
  $log_file            = '/var/log/glance/registry.log',
  $log_dir             = '/var/log/glance',
  $sql_connection      = 'sqlite:///var/lib/glance/glance.sqlite',
  $sql_idle_timeout    = '3600',
  $auth_type           = 'keystone',
  $auth_host           = '127.0.0.1',
  $auth_port           = '35357',
  $auth_protocol       = 'http',
  $keystone_tenant     = 'admin',
  $keystone_user       = 'admin',
  $enabled             = true,
  $use_syslog          = false,
  $syslog_log_facility = 'LOG_LOCAL2',
  $idle_timeout        = '3600',
  $max_pool_size       = '10',
  $max_overflow        = '30',
  $max_retries         = '-1',
) inherits glance {

File {
  ensure  => present,
  owner   => 'glance',
  group   => 'glance',
  mode    => '0640',
  notify  => Service['glance-registry'],
  require => Class['glance']
}

  # Logging
  if $log_file {
    glance_registry_config {
      'DEFAULT/log_file': value  => $log_file;
    }
  } else {
    glance_registry_config {
      'DEFAULT/log_file': ensure => absent;
    }
  }

  if $log_dir {
    glance_registry_config {
      'DEFAULT/log_dir': value  => $log_dir;
    }
  } else {
    glance_registry_config {
      'DEFAULT/log_dir': ensure => absent;
    }
  }

  # Syslog
  if $use_syslog {
    glance_registry_config {
      'DEFAULT/use_syslog':            value => true;
      'DEFAULT/use_syslog_rfc_format': value => true;
      'DEFAULT/syslog_log_facility':   value => $syslog_log_facility;
    }
  } else {
    glance_registry_config {
      'DEFAULT/use_syslog': value => false;
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
  }

  #TODO(bogdando) check for deprecation names in J
  # Deprecated group/name - [DEFAULT]/sql_max_pool_size > [DATABASE]/max_pool_size
  # Deprecated group/name - [DATABASE]/sql_max_pool_size
  # Deprecated group/name - [DEFAULT]/sql_max_retries > [DATABASE]/max_retries
  # Deprecated group/name - [DATABASE]/sql_max_retries
  # Deprecated group/name - [DEFAULT]/sql_max_overflow > [DATABASE]/max_overflow
  # Deprecated group/name - [DATABASE]/sql_max_overflow
  # Deprecated group/name - [DEFAULT]/sql_idle_timeout > [DATABASE]/idle_timeout
  # Deprecated group/name - [DATABASE]/sql_idle_timeout
  glance_registry_config {
    'DEFAULT/sql_max_pool_size': value => $max_pool_size;
    'DEFAULT/sql_max_retries':   value => $max_retries;
    'DEFAULT/sql_max_overflow':  value => $max_overflow;
    'DEFAULT/sql_idle_timeout':  value => $idle_timeout;
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
  Package<| title == 'glance-registry'|> ~> Service<| title == 'glance-registry'|>
  if !defined(Service['glance-registry']) {
    notify{ "Module ${module_name} cannot notify service glance-registry\
 on package update": }
  }
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
