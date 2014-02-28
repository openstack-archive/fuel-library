# Installs & configure the murano conductor  service

class murano::conductor (
  $log_file                            = '/var/log/murano/murano-conductor.log',
  $use_syslog                          = false,
  $syslog_log_facility                 = 'LOG_LOCAL0',
  $debug                               = false,
  $verbose                             = false,
  $data_dir                            = '/var/cache/murano',
  $max_environments                    = '20',
  $auth_url                            = 'http://127.0.0.1:5000/v2.0',
  $rabbit_host                         = '127.0.0.1',
  $rabbit_port                         = '5672',
  $rabbit_ssl                          = false,
  $rabbit_ca_certs                     = '',
  $rabbit_ca                           = '',
  $rabbit_login                        = 'murano',
  $rabbit_password                     = 'murano',
  $rabbit_virtual_host                 = '/',
  $init_scripts_dir                    = '/etc/murano/init-scripts',
  $agent_config_dir                    = '/etc/murano/agent-config',
  $use_neutron                         = false
) {

  include murano::params

  package { 'murano_conductor':
    ensure => installed,
    name   => $::murano::params::murano_conductor_package_name,
  }

  service { 'murano_conductor':
    ensure     => 'running',
    name       => $::murano::params::murano_conductor_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  if $use_neutron {
    $network_topology = 'routed'
  } else {
    $network_topology = 'nova'
  }

  $logging_file = '/etc/murano/murano-conductor-logging.conf'
  if $use_syslog and !$debug { #syslog and nondebug case
    murano_conductor_config {
      'DEFAULT/log_config'         : value => $logging_file;
      'DEFAULT/use_syslog'         : value => true;
      'DEFAULT/syslog_log_facility': value => $syslog_log_facility;
    }
    file {"murano-conductor-logging.conf":
      content => template('murano/logging.conf.erb'),
      path    => $logging_file,
      require => Package['murano_conductor'],
      notify  => Service['murano_conductor'],
    }
  } else { #other syslog debug or nonsyslog debug/nondebug cases
    murano_conductor_config {
      'DEFAULT/log_config': ensure => absent;
      'DEFAULT/log_file'  : value  => $log_file;
      'DEFAULT/use_syslog': value  => false;
    }
  }

  murano_conductor_config {
    'DEFAULT/debug'                    : value => $debug;
    'DEFAULT/verbose'                  : value => $verbose;
    'DEFAULT/data_dir'                 : value => "${data_dir}/muranoconductor-cache";
    'DEFAULT/max_environments'         : value => $max_environments;
    'DEFAULT/init_scripts_dir'         : value => $init_scripts_dir;
    'DEFAULT/agent_config_dir'         : value => $agent_config_dir;
    'DEFAULT/network_topology'        : value => $network_topology;
    'keystone/auth_url'                : value => $auth_url;
    'rabbitmq/host'                    : value => $rabbit_host;
    'rabbitmq/port'                    : value => $rabbit_port;
    'rabbitmq/ssl'                     : value => $rabbit_ssl;
    'rabbitmq/ca_certs'                : value => $rabbit_ca;
    'rabbitmq/login'                   : value => $rabbit_login;
    'rabbitmq/password'                : value => $rabbit_password;
    'rabbitmq/virtual_host'            : value => $rabbit_virtual_host;
  }

  Package['murano_conductor'] -> Murano_conductor_config<||> ~> Service['murano_conductor']
}
