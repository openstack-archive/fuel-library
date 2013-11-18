# Installs & configure the murano conductor  service

class murano::conductor (
  $log_file                            = '/var/log/murano/conductor.log',
  $debug                               = 'True',
  $verbose                             = 'True',
  $data_dir                            = '/etc/murano',
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

  murano_conductor_config {
    'DEFAULT/log_file'                 : value => $log_file;
    'DEFAULT/debug'                    : value => $debug;
    'DEFAULT/verbose'                  : value => $verbose;
    'DEFAULT/data_dir'                 : value => $data_dir;
    'DEFAULT/max_environments'         : value => $max_environments;
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
