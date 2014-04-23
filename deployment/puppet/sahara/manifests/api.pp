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
  $syslog_log_facility_sahara  = "LOG_LOCAL0",
  $log_dir                     = '/var/log/sahara',
  $log_file                    = '/var/log/sahara/api.log',
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

  # Log configuration
  if $log_dir {
    sahara_config {
      'DEFAULT/log_dir' :  value  => $log_dir;
    }
  } else {
    sahara_config {
      'DEFAULT/log_dir' :  ensure => absent;
    }
  }

  if $log_file {
    sahara_config {
      'DEFAULT/log_file' :  value  => $log_file;
    }
  } else {
    sahara_config {
      'DEFAULT/log_file' :  ensure => absent;
    }
  }

  # Syslog configuration
  if $use_syslog {
    sahara_config {
      'DEFAULT/use_syslog':            value => true;
      'DEFAULT/use_syslog_rfc_format': value => true;
      'DEFAULT/syslog_log_facility':   value => $syslog_log_facility;
    }
  } else {
    sahara_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

  file { $log_dir:
    ensure  => directory,
    mode    => '0751',
  }

  Package['sahara'] -> Sahara_config<||> -> Exec['sahara-db-manage'] -> Service['sahara-api']
  Package<| title == 'sahara'|> ~> Service<| title == 'sahara-api'|>
  if !defined(Service['sahara-api']) {
    notify{ "Module ${module_name} cannot notify service sahara-api on package update": }
  }

}
