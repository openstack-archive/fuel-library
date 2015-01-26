# Installs & configure the sahara API service

class sahara::api (
  $enabled                     = true,
  $auth_uri                    = 'http://127.0.0.1:5000/v2.0/',
  $identity_uri                = 'http://127.0.0.1:35357/',
  $keystone_user               = 'sahara',
  $keystone_tenant             = 'services',
  $keystone_password           = 'sahara',
  $bind_port                   = '8386',
  $node_domain                 = 'novalocal',
  $sql_connection              = 'mysql://sahara:sahara@localhost/sahara',
  $use_neutron                 = false,
  $debug                       = false,
  $verbose                     = false,
  $use_syslog                  = false,
  $syslog_log_facility         = "LOG_LOCAL0",
  $log_dir                     = '/var/log/sahara',
  $log_file                    = '/var/log/sahara/api.log',
  $templates_dir               = '/usr/share/sahara/templates',
  $service_name                = $sahara::params::service_name,
  $package_name                = $sahara::params::package_name,
  $use_floating_ips            = false,
  $openstack_version,
) inherits sahara::params {

  validate_string($keystone_password)

  package { 'sahara':
    ensure => installed,
    name   => $package_name,
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

  exec { 'sahara-db-manage':
    command    => "/usr/bin/sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head"
  }

  #NOTE(mattymo): Backward compatibility for Icehouse
  case $openstack_version {
    /2014.2-6./: {
      $service_name_real = 'sahara-all'
    }
    /2014.1.*/: {
      $service_name_real = 'sahara-api'
    }
    default: {
      fail("Unsupported OpenStack version: ${openstack_version}")
    }
  }

  service { 'sahara-api':
    ensure     => $service_ensure,
    name       => $service_name_real, # change back to $service_name when hacks are removed
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  sahara_config {
    'DEFAULT/use_neutron'                  : value => $use_neutron_value;
    'DEFAULT/node_domain'                  : value => $node_domain;
    'database/connection'                  : value => $sql_connection;
    'database/max_retries'                 : value => '-1';
    'DEFAULT/verbose'                      : value => $verbose;
    'DEFAULT/debug'                        : value => $debug;
  }

  #NOTE(mattymo): Backward compatibility for Icehouse
  case $openstack_version {
    /2014.1.*-6/: {
      $plugins = "vanilla,hdp"
      #parse keystone_host for backward compatibility
      $keystone_host = inline_template("<%= @auth_uri.split('://')[1].split('/')[0].split(':')[0] %>")
      $keystone_port  = inline_template("<%= @auth_uri.split(':')[2].split('/')[0] %>")
      sahara_config {
        'DEFAULT/os_admin_tenant_name'         : value => $keystone_tenant;
        'DEFAULT/os_admin_username'            : value => $keystone_user;
        'DEFAULT/os_admin_password'            : value => $keystone_password;
        'DEFAULT/os_auth_host'                 : value => $keystone_host;
        'DEFAULT/os_auth_port'                 : value => $keystone_port;
        'DEFAULT/use_floating_ips'             : value => $use_floating_ips;
        'DEFAULT/plugins'                      : value => $plugins;
      }
    }
    /2014.2.*-6/: {
      sahara_config {
        'keystone_authtoken/admin_tenant_name' : value => $keystone_tenant;
        'keystone_authtoken/admin_user'        : value => $keystone_user;
        'keystone_authtoken/admin_password'    : value => $keystone_password;
        'keystone_authtoken/auth_uri'          : value => $auth_uri;
        'keystone_authtoken/identity_uri'      : value => $identity_uri;
      }
    }
    default: {
      fail("Unsupported OpenStack version: ${openstack_version}")
    }
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
      'DEFAULT/use_syslog':            value => false;
    }
  }

  file { $log_dir:
    ensure  => directory,
    mode    => '0751',
  }

  if $use_neutron {
    $network_provider = "neutron"
  } else {
    $network_provider = "nova"
  }

  class { 'sahara::templates::create_templates':
    network_provider => $network_provider,
    templates_dir    => $templates_dir,
  }

  Package['sahara'] ->
  Sahara_config<||> ->
  Exec['sahara-db-manage'] ->
  Service['sahara-api'] ->
  Class['sahara::templates::create_templates']

  if $use_neutron {
     Neutron_network<||> -> Class['sahara::templates::create_templates']
  } else {
     Nova_network<||> -> Class['sahara::templates::create_templates']
  }

  Package<| title == 'sahara'|> ~> Service<| title == 'sahara-api'|>

  if !defined(Service['sahara-api']) {
    notify{ "Module ${module_name} cannot notify service sahara-api on package update": }
  }

}
