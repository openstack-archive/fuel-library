class murano::api (
    $use_syslog                 = false,
    $syslog_log_facility        = 'LOG_LOCAL0',
    $verbose                    = false,
    $debug                      = false,
    $auth_host                  = '127.0.0.1',
    $auth_port                  = '35357',
    $auth_protocol              = 'http',
    $admin_tenant_name          = 'admin',
    $admin_user                 = 'admin',
    $admin_password             = 'admin',
    $signing_dir                = '/tmp/keystone-signing-muranoapi',
    $bind_host                  = '0.0.0.0',
    $bind_port                  = '8082',
    $api_host                   = 'localhost',
    $log_file                   = '/var/log/murano/murano.log',
    # rabbit_host and rabbit_port are required for
    #   murano-engine rabbitmq section. It doesn't use oslo.messaging yet.
    $rabbit_host                = '127.0.0.1',
    $rabbit_port                = '5672',
    # rabbit_hosts and rabbit_ha_queues are required for
    #    murano-api rabbitmq configuration via oslo.messaging.
    $rabbit_ha_hosts            = '127.0.0.1:5672',
    $rabbit_ha_queues           = false,
    $rabbit_use_ssl             = false,
    $rabbit_ca_certs            = '',
    $rabbit_login               = 'murano',
    $rabbit_password            = 'murano',
    $rabbit_virtual_host        = '/',
    $firewall_rule_name         = '202 murano-api',
    $murano_db_user             = 'murano',
    $murano_db_password         = 'murano',
    $murano_db_host             = 'localhost',
    $murano_db_name             = 'murano',

    $murano_user                = 'murano',
    $stats_period               = '5',

    $primary_controller         = true,
) {

  $database_connection = "mysql://${murano_db_name}:${murano_db_password}@${murano_db_host}:3306/${murano_db_name}?read_timeout=60"
  $keystone_auth_url = "${auth_protocol}://${auth_host}:${auth_port}/v2.0"
  $murano_api_url = "http://${api_host}:${bind_port}"

  include murano::params

  package { 'murano':
    ensure => installed,
    name   => $::murano::params::murano_package_name,
  }

  service { 'murano_api':
    ensure     => 'running',
    name       => $::murano::params::murano_api_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  service { 'murano_engine':
    ensure     => 'running',
    name       => $::murano::params::murano_engine_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  Package<| title == 'murano'|> ~> Service<| title == 'murano_api'|>
  Package<| title == 'murano'|> ~> Service<| title == 'murano_engine'|>

  if !defined(Service['murano_api']) {
    notify{ "Module ${module_name} cannot notify service murano-api on package update": }
  }

  if !defined(Service['murano_engine']) {
    notify{ "Module ${module_name} cannot notify service murano-engine on package update": }
  }

  if $use_syslog {
    murano_config {
      'DEFAULT/use_syslog'           : value => true;
      'DEFAULT/use_syslog_rfc_format': value => true;
      'DEFAULT/syslog_log_facility'  : value => $syslog_log_facility;
    }
  }

  murano_config {
    'DEFAULT/verbose'                       : value => $verbose;
    'DEFAULT/debug'                         : value => $debug;
    'DEFAULT/bind_host'                     : value => $bind_host;
    'DEFAULT/bind_port'                     : value => $bind_port;
    'DEFAULT/log_file'                      : value => $log_file;
    # oslo.messaging configuration (for murano-api).
    'DEFAULT/rabbit_hosts'                  : value => $rabbit_ha_hosts;
    'DEFAULT/rabbit_ha_queues'              : value => $rabbit_ha_queues;
    'DEFAULT/rabbit_use_ssl'                : value => $rabbit_use_ssl;
    'DEFAULT/rabbit_userid'                 : value => $rabbit_login;
    'DEFAULT/rabbit_password'               : value => $rabbit_password;
    'DEFAULT/rabbit_virtual_host'           : value => $rabbit_virtual_host;
    'DEFAULT/kombu_ssl_ca_certs'            : value => $rabbit_ca_certs;
    # Direct RabbitMQ client configuration (for murano-engine).
    # FIXME(dteselkin): murano-engine doesn't support oslo.messaging yet
    #    so additional configuration is required.
    'rabbitmq/host'                         : value => $rabbit_host;
    'rabbitmq/port'                         : value => $rabbit_port;
    'rabbitmq/ssl'                          : value => $rabbit_use_ssl;
    'rabbitmq/login'                        : value => $rabbit_login;
    'rabbitmq/password'                     : value => $rabbit_password;
    'rabbitmq/virtual_host'                 : value => $rabbit_virtual_host;
    'rabbitmq/ca_certs'                     : value => $rabbit_ca_certs;

    'database/connection'                   : value => $database_connection;

    'murano/url'                            : value => $murano_api_url;

    'keystone/auth_url'                     : value => $keystone_auth_url;

    'keystone_authtoken/auth_host'          : value => $auth_host;
    'keystone_authtoken/auth_port'          : value => $auth_port;
    'keystone_authtoken/auth_protocol'      : value => $auth_protocol;
    'keystone_authtoken/admin_tenant_name'  : value => $admin_tenant_name;
    'keystone_authtoken/admin_user'         : value => $admin_user;
    'keystone_authtoken/admin_password'     : value => $admin_password;
    'keystone_authtoken/signing_dir'        : value => $signing_dir;
  }

  firewall { $firewall_rule_name :
    dport   => [ $bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  Package['murano'] -> Murano_config<||>

  if $primary_controller {
    $murano_manage = '/usr/bin/murano-db-manage'
    exec { 'murano_manage_db_sync':
      path    => [ '/usr/bin' ],
      command => "$murano_manage --config-file=/etc/murano/murano.conf upgrade",
      user    => $murano_user,
      group   => $murano_user,
      onlyif  => "test -f $murano_manage",
    }

    Murano_config<||> -> Exec['murano_manage_db_sync']

    murano::application_package{'io.murano':
      mandatory => true
    }
    murano::application_package{'io.murano.lib.networks.Neutron':
      mandatory => true
    }

    Exec['murano_manage_db_sync'] -> Murano::Application_package<| mandatory == true |>
  }

  #Package['murano'] -> Service['murano_api']
  Murano_config<||> ~> Service['murano_api']
  Murano_paste_ini_config<||> ~> Service['murano_api']
  Exec<| title == 'murano_manage_db_sync' |> ~> Service['murano_api']

  #Package['murano'] -> Service['murano_engine']
  Murano_config<||> ~> Service['murano_engine']
  Murano_paste_ini_config<||> ~> Service['murano_engine']
  Exec<| title == 'murano_manage_db_sync' |> ~> Service['murano_engine']

}
