# Installs & configure the sahara API service

class sahara::api (
  $enabled                     = true,
  $keystone_host               = '127.0.0.1',
  $keystone_port               = '35357',
  $keystone_protocol           = 'http',
  $keystone_user               = 'sahara',
  $keystone_tenant             = 'services',
  $keystone_password           = 'sahara',
  $bind_port                   = '8386',
  $node_domain                 = 'novalocal',
  $plugins                     = 'vanilla,hdp',
  $sql_connection              = 'mysql://sahara:sahara@localhost/sahara',
  $use_neutron                 = false,
  $use_floating_ips            = true,
  $debug                       = false,
  $verbose                     = false,
  $use_syslog                  = false,
  $syslog_log_level            = 'WARNING',
  $syslog_log_facility_sahara  = "LOG_LOCAL0",
  $logdir                      = '/var/log/sahara',
) inherits sahara::params {

  validate_string($keystone_password)

  package { 'sahara':
    ensure => installed,
    name   => $sahara::params::sahara_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if $use_neutron {
    $use_neutron_value = true
  } else {
    $use_neutron_value = false
  }

  if $use_floating_ips {
    $use_floating_ips_value = true
  } else {
    $use_floating_ips_value = false
  }

  exec { 'sahara-db-manage':
    command    => "/usr/bin/sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head"
  }

  service { 'sahara-api':
    ensure     => $service_ensure,
    name       => $sahara::params::sahara_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  sahara_config {
    'DEFAULT/os_admin_tenant_name'         : value => $keystone_tenant;
    'DEFAULT/os_admin_username'            : value => $keystone_user;
    'DEFAULT/os_admin_password'            : value => $keystone_password;
    'DEFAULT/os_auth_host'                 : value => $keystone_host;
    'DEFAULT/os_auth_port'                 : value => $keystone_port;
    'DEFAULT/use_floating_ips'             : value => $use_floating_ips_value;
    'DEFAULT/use_neutron'                  : value => $use_neutron_value;
    'DEFAULT/node_domain'                  : value => $node_domain;
    'DEFAULT/plugins'                      : value => $plugins;
    'database/connection'                  : value => $sql_connection;
    'database/max_retries'                 : value => '-1';
    'DEFAULT/verbose'                      : value => $verbose;
    'DEFAULT/debug'                        : value => $debug;
  }

  $logging_file = '/etc/sahara/logging.conf'
  case $::osfamily {
    'Debian': {
       $log_file = 'sahara-api.log'
     }
    'RedHat': {
       $log_file = 'api.log'
     }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, \
module ${module_name} only support osfamily RedHat and Debian")
    }
  }

  if $use_syslog and !$debug {
    sahara_config {
      'DEFAULT/log_config'                    : value  => $logging_file;
      'DEFAULT/log_file'                      : ensure => absent;
      'DEFAULT/use_syslog'                    : value  => true;
      'DEFAULT/use_stderr'                    : value  => false;
      'DEFAULT/syslog_log_facility'           : value  => $syslog_log_facility_sahara;
    }
    file { 'sahara-logging.conf' :
      ensure  => present,
      content => template('sahara/logging.conf.erb'),
      path    => $logging_file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package['sahara'],
      notify  => Service['sahara-api'],
    }
  } else {
    sahara_config {
      'DEFAULT/log_config'                   : ensure => absent;
      'DEFAULT/use_syslog'                   : ensure => absent;
      'DEFAULT/use_stderr'                   : ensure => absent;
      'DEFAULT/syslog_log_facility'          : ensure => absent;
      'DEFAULT/log_dir'                      : value  => $logdir;
      'DEFAULT/log_file'                     : value  => $log_file;
    }
    file { 'sahara-logging.conf' :
      ensure  => absent,
      path    => $logging_file,
    }
  }

  File[$logdir] -> File['sahara-logging.conf']
  File['sahara-logging.conf'] ~> Service <| title == 'sahara-api' |>
  File['sahara-logging.conf'] -> Sahara_config['DEFAULT/log_config']

  file { $logdir:
    ensure  => directory,
    mode    => '0751',
  }

  Package['sahara'] -> Sahara_config<||> -> Exec['sahara-db-manage'] -> Service['sahara-api']
  Package<| title == 'sahara'|> ~> Service<| title == 'sahara-api'|>
  if !defined(Service['sahara-api']) {
    notify{ "Module ${module_name} cannot notify service sahara-api on package update": }
  }

}
