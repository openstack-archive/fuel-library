# Installs & configure the savanna API service

class savanna::api (
  $enabled                     = true,
  $keystone_host               = '127.0.0.1',
  $keystone_port               = '35357',
  $keystone_protocol           = 'http',
  $keystone_user               = 'savanna',
  $keystone_tenant             = 'services',
  $keystone_password           = 'savanna',
  $bind_port                   = '8386',
  $node_domain                 = 'novalocal',
  $plugins                     = 'vanilla,hdp,idh',
  $vanilla_plugin_class        = 'savanna.plugins.vanilla.plugin:VanillaProvider',
  $hdp_plugin_class            = 'savanna.plugins.hdp.ambariplugin:AmbariPlugin',
  $idh_plugin_class            = 'savanna.plugins.intel.plugin:IDHProvider',
  $sql_connection              = 'mysql://savanna:savanna@localhost/savanna',
  $use_neutron                 = false,
  $use_floating_ips            = true,
  $debug                       = false,
  $verbose                     = false,
  $use_syslog                  = false,
  $syslog_log_level            = 'WARNING',
  $syslog_log_facility_savanna = "LOG_LOCAL0",
  $logdir                      = '/var/log/savanna',
) inherits savanna::params {

  validate_string($keystone_password)

  package { 'savanna':
    ensure => installed,
    name   => $savanna::params::savanna_package_name,
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

  service { 'savanna-api':
    ensure     => $service_ensure,
    name       => $savanna::params::savanna_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  savanna_config {
    'DEFAULT/os_admin_tenant_name'         : value => $keystone_tenant;
    'DEFAULT/os_admin_username'            : value => $keystone_user;
    'DEFAULT/os_admin_password'            : value => $keystone_password;
    'DEFAULT/os_auth_host'                 : value => $keystone_host;
    'DEFAULT/os_auth_port'                 : value => $keystone_port;
    'DEFAULT/use_floating_ips'             : value => $use_floating_ips_value;
    'DEFAULT/use_neutron'                  : value => $use_neutron_value;
    'DEFAULT/node_domain'                  : value => $node_domain;
    'DEFAULT/plugins'                      : value => $plugins;
    'plugin:vanilla/plugin_class'          : value => $vanilla_plugin_class;
    'plugin:hdp/plugin_class'              : value => $hdp_plugin_class;
    'plugin:idh/plugin_class'              : value => $idh_plugin_class;
    'database/connection'                  : value => $sql_connection;
    'DEFAULT/verbose'                      : value => $verbose;
    'DEFAULT/debug'                        : value => $debug;
    'database/max_retries'                 : value => -1;
  }

  $logging_file = '/etc/savanna/logging.conf'
  case $::osfamily {
    'Debian': {
       $log_file = 'savanna-api.log'
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
    savanna_config {
      'DEFAULT/log_config'                    : value  => $logging_file;
      'DEFAULT/use_syslog'                    : value  => true;
      'DEFAULT/syslog_log_facility'           : value  => $syslog_log_facility_savanna;
    }
    file { 'savanna-logging.conf' :
      ensure  => present,
      content => template('savanna/logging.conf.erb'),
      path    => $logging_file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package['savanna'],
      notify  => Service['savanna-api'],
    }
  } else {
    savanna_config {
      'DEFAULT/log_config'                   : ensure => absent;
      'DEFAULT/use_syslog'                   : ensure => absent;
      'DEFAULT/use_stderr'                   : ensure => absent;
      'DEFAULT/syslog_log_facility'          : ensure => absent;
      'DEFAULT/log_dir'                      : value  => $logdir;
      'DEFAULT/log_file'                     : value  => $log_file;
    }
    file { 'savanna-logging.conf' :
      ensure  => absent,
      path    => $logging_file,
    }
  }

  File[$logdir] -> File['savanna-logging.conf']
  File['savanna-logging.conf'] -> Savanna_config['DEFAULT/log_config']

  file { $logdir:
    ensure  => directory,
    mode    => '0751',
  }

  Package['savanna'] -> Savanna_config<||> -> Service['savanna-api']

}
