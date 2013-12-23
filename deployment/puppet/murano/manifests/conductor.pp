# Installs & configure the murano conductor  service

class murano::conductor (
  $log_file                            = '/var/log/murano/murano-conductor.log',
  $use_syslog                          = 'True',
  $syslog_log_facility                 = 'LOCAL0',
  $debug                               = 'True',
  $verbose                             = 'True',
  $data_dir                            = '/var/cache/murano',
  $max_environments                    = '20',
  $auth_url                            = 'http://127.0.0.1:5000/v2.0',
  $rabbit_host                         = '127.0.0.1',
  $rabbit_port                         = '5672',
  $rabbit_ssl                          = 'False',
  $rabbit_ca_certs                     = '',
  $rabbit_ca                           = '',
  $rabbit_login                        = 'murano',
  $rabbit_password                     = 'murano',
  $rabbit_virtual_host                 = '/',
  $init_scripts_dir                    = '/etc/murano/init-scripts',
  $agent_config_dir                    = '/etc/murano/agent-config',
  $use_neutron                         = 'True'
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

  if $use_syslog and !$debug =~ /(?i)(true|yes)/ {
    murano_conductor_config {
      'DEFAULT/use_syslog'          : value  => true;
      'DEFAULT/use_stderr'          : ensure => absent;
      'DEFAULT/syslog_log_facility' : value  => $syslog_log_facility;
      'DEFAULT/log_file'            : ensure => absent;
    }

    file { 'murano-conductor-logging.conf':
      content => template('murano/logging.conf.erb'),
      path    => '/etc/murano/murano-conductor-logging.conf',
    }
  }
  else {
    murano_conductor_config {
      'DEFAULT/use_syslog'          : ensure => absent;
      'DEFAULT/use_stderr'          : ensure => absent;
      'DEFAULT/syslog_log_facility' : ensure => absent;
      'DEFAULT/log_file'            : value  => $log_file;
      'DEFAULT/logging_context_format_string':
      value => '%(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s [%(request_id)s %(user)s %(tenant)s] %(instance)s%(message)s';
      'DEFAULT/logging_default_format_string':
      value => '%(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s';
    }

    file { 'murano-conductor-logging.conf':
      content => template('murano/logging.conf-nosyslog.erb'),
      path    => '/etc/murano/murano-conductor-logging.conf',
    }
    }
  }

  murano_conductor_config {
    'DEFAULT/debug'                    : value => $debug;
    'DEFAULT/verbose'                  : value => $verbose;
    'DEFAULT/data_dir'                 : value => "${data_dir}/muranoconductor-cache";
    'DEFAULT/log_config_append'        : value  => '/etc/murano/murano-conductor-logging.conf';
    'DEFAULT/max_environments'         : value => $max_environments;
    'DEFAULT/init_scripts_dir'         : value => $init_scripts_dir;
    'DEFAULT/agent_config_dir'         : value => $agent_config_dir;
    'DEFAULT/anetwork_topology'        : value => $network_topology;
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
  File['murano-conductor-logging.conf'] ~> Service['murano_conductor']

}

