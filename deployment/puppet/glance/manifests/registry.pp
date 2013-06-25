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
  $use_syslog = false
) inherits glance {
  
  if $use_syslog {
    glance_registry_config {'DEFAULT/log_config': value => "/etc/glance/logging.conf";}
  }

  require 'keystone::python'

  validate_re($sql_connection, '(sqlite|mysql|posgres):\/\/(\S+:\S+@\S+\/\S+)?')

  Package['glance'] -> Glance_registry_config<||>
  Glance_registry_config<||> ~> Exec<| title == 'glance-manage db_sync' |>
  Glance_registry_config<||> ~> Service['glance-registry']

  File {
    ensure  => present,
    owner   => 'glance',
    group   => 'glance',
    mode    => '0640',
    notify  => Service['glance-registry'],
    require => Class['glance']
  }

  if($sql_connection =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
    require 'mysql::python'
  } elsif($sql_connection =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

  } elsif($sql_connection =~ /sqlite:\/\//) {

  } else {
    fail("Invalid db connection ${sql_connection}")
  }

  # basic service config
  glance_registry_config {
    'DEFAULT/verbose':   value => $verbose;
    'DEFAULT/debug':     value => $debug;
    'DEFAULT/bind_host': value => $bind_host;
    'DEFAULT/bind_port': value => $bind_port;
    'DEFAULT/log_file': value => "/var/log/glance/registry.log";
    'DEFAULT/backlog': value => "4096";
    'DEFAULT/api_limit_max': value => "1000";
    'DEFAULT/limit_param_default': value => "25";
    'DEFAULT/use_syslog': value => $use_syslog;
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
