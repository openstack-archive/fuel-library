class glance::registry(
  $log_verbose       = 'False',
  $log_debug         = 'False',
  $bind_host         = '0.0.0.0',
  $bind_port         = '9191',
  $log_file          = '/var/log/glance/registry.log',
  $sql_connection    = 'sqlite:///var/lib/glance/glance.sqlite',
  $sql_idle_timeout  = '3600',
  $auth_type         = 'keystone',
  $auth_host         = '127.0.0.1',
  $auth_port         = '35357',
  $auth_protocol     = 'http',
  $keystone_password = 'ChangeMe',
  $enabled           = true
) inherits glance {

  require 'keystone::python'

  validate_re($sql_connection, '(sqlite|mysql|posgres):\/\/(\S+:\S+@\S+\/\S+)?')

  Package['glance'] -> Glance_registry_config<||>
  Glance_registry_config<||> ~> Exec['glance-manage db_sync']
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
    Package['python-mysqldb'] -> Exec['glance-manage db_sync']
    ensure_resource( 'package', 'python-mysqldb', {'ensure' => 'present'})
  } elsif($sql_connection =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

  } elsif($sql_connection =~ /sqlite:\/\//) {

  } else {
    fail("Invalid db connection ${sql_connection}")
  }

  # basic service config
  glance_registry_config {
    'DEFAULT/verbose':   value => $log_verbose;
    'DEFAULT/debug':     value => $log_debug;
    'DEFAULT/bind_host': value => $bind_host;
    'DEFAULT/bind_port': value => $bind_port;
  }

  # db connection config
  glance_registry_config {
    'DEFAULT/sql_connection':   value => $sql_connection;
    'DEFAULT/sql_idle_timeout': value => $sql_idle_timeout;
  }

  # auth config
  glance_registry_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/protocol':          value => $protocol;
    'keystone_authtoken/auth_uri':          value => $auth_uri;
  }

  # keystone config
  if $auth_type == 'keystone' {
    glance_registry_config {
      'paste_deploy/flavor':                  value => 'keystone';
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_user':        value => $keystone_user;
      'keystone_authtoken/admin_password':    value => $keystone_password;
    }
  }

  file { ['/etc/glance/glance-registry.conf',
          '/etc/glance/glance-registry-paste.ini'
         ]:
  }

  if $enabled {

    exec { 'glance-manage db_sync':
      command     => $::glance::params::db_sync_command,
      path        => '/usr/bin',
      user        => 'glance',
      refreshonly => true,
      logoutput   => on_failure,
      subscribe   => [Package['glance'], File['/etc/glance/glance-registry.conf']],
      notify      => Service['glance-registry'],
    }
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'glance-registry':
    name       => $::glance::params::registry_service_name,
    ensure     => $service_ensure,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => File['/etc/glance/glance-registry.conf'],
    require    => Class['glance']
  }

}
