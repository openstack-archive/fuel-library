class glance::registry(
  $log_verbose = 'False',
  $log_debug = 'False',
  $bind_host = '0.0.0.0',
  $bind_port = '9191',
  $log_file = '/var/log/glance/registry.log',
  $sql_connection = 'sqlite:///var/lib/glance/glance.sqlite',
  $sql_idle_timeout = '3600',
  $auth_type = 'keystone',
  $service_protocol = 'http',
  $service_host = '127.0.0.1',
  $service_port = '5000',
  $auth_host = '127.0.0.1',
  $auth_port = '35357',
  $auth_protocol = 'http',
  $auth_uri = 'http://127.0.0.1:5000/',
  $admin_token = '999888777666',
  $keystone_tenant = 'admin',
  $keystone_user = 'admin',
  $keystone_password = 'ChangeMe'
) inherits glance {

  if($auth_type == 'keystone') {
    $context_type = 'context'
  } else {
    $context_type = 'auth-context'
  }

  File {
    ensure  => present,
    owner   => 'glance',
    group   => 'root',
    mode    => '0640',
    notify  => Service['glance-registry'],
    require => Class['glance']
  }

  file { '/etc/glance/glance-registry.conf':
    content => template('glance/glance-registry.conf.erb'),
  }

  file { '/etc/glance/glance-registry-paste.ini':
    content => template('glance/glance-registry-paste.ini.erb'),
  }

  service { 'glance-registry':
    name       => $::glance::params::registry_service_name,
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => File['/etc/glance/glance-registry.conf'],
    require    => Class['glance']
  }

}
