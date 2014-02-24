class murano::api (
    $use_syslog                     = false,
    $syslog_log_facility            = 'LOG_LOCAL0',
    $verbose                        = false,
    $debug                          = false,
    $api_paste_inipipeline          = 'authtoken context apiv1app',
    $api_paste_app_factory          = 'muranoapi.api.v1.router:API.factory',
    $api_paste_filter_factory       = 'muranoapi.api.middleware.context:ContextMiddleware.factory',
    $api_paste_paste_filter_factory = 'keystoneclient.middleware.auth_token:filter_factory',
    $api_paste_auth_host            = '127.0.0.1',
    $api_paste_auth_port            = '35357',
    $api_paste_auth_protocol        = 'http',
    $api_paste_admin_tenant_name    = 'admin',
    $api_paste_admin_user           = 'admin',
    $api_paste_admin_password       = 'admin',
    $api_paste_signing_dir          = '/tmp/keystone-signing-muranoapi',
    $api_bind_host                  = '0.0.0.0',
    $api_bind_port                  = '8082',
    $api_log_file                   = '/var/log/murano/murano-api.log',
    $api_database_auto_create       = true,
    $api_reports_results_exchange   = 'task-results',
    $api_reports_results_queue      = 'task-results',
    $api_reports_reports_exchange   = 'task-reports',
    $api_reports_reports_queue      = 'task-reports',
    $api_rabbit_host                = '127.0.0.1',
    $api_rabbit_port                = '5672',
    $api_rabbit_ssl                 = false,
    $api_rabbit_ca_certs            = '',
    $api_rabbit_login               = 'murano',
    $api_rabbit_password            = 'murano',
    $api_rabbit_virtual_host        = '/',
    $firewall_rule_name             = '202 murano-api',

    $murano_db_password             = 'murano',
    $murano_db_name                 = 'murano',
    $murano_db_user                 = 'murano',
    $murano_db_host                 = 'localhost',
) {

  $api_database_connection = "mysql://${murano_db_name}:${murano_db_password}@${murano_db_host}:3306/${murano_db_name}"

  include murano::params

  package { 'murano_api':
    ensure => installed,
    name   => $::murano::params::murano_api_package_name,
  }

  service { 'murano_api':
    ensure     => 'running',
    name       => $::murano::params::murano_api_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  if $use_syslog and !$debug {
    murano_api_config {
      'DEFAULT/log_config_append'    : value => '/etc/murano/murano-api-logging.conf';
      'DEFAULT/use_syslog'           : value  => true;
      'DEFAULT/use_stderr'           : ensure => absent;
      'DEFAULT/syslog_log_facility'  : value  => $syslog_log_facility;
      'DEFAULT/log_file'             : ensure => absent;
    }

    file { "murano-api-logging.conf":
      content => template('murano/logging.conf.erb'),
      path    => '/etc/murano/murano-api-logging.conf',
    }
  } else {
    murano_api_config {
      'DEFAULT/log_config_append'   : ensure => absent;
      'DEFAULT/use_syslog'          : ensure => absent;
      'DEFAULT/use_stderr'          : ensure => absent;
      'DEFAULT/syslog_log_facility' : ensure => absent;
      'DEFAULT/log_file'            : value  => $api_log_file;
    }

    file { "murano-api-logging.conf":
      content => template('murano/logging.conf-nosyslog.erb'),
      path    => '/etc/murano/murano-api-logging.conf',
    }
  }

  murano_api_config {
    'DEFAULT/verbose'                       : value => $verbose;
    'DEFAULT/debug'                         : value => $debug;
    'DEFAULT/bind_host'                     : value => $api_bind_host;
    'DEFAULT/bind_port'                     : value => $api_bind_port;
    'DEFAULT/logging_context_format_string':
    value => 'murano-api %(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s [%(request_id)s %(user)s %(tenant)s] %(instance)s%(message)s';
    'DEFAULT/logging_default_format_string':
    value => 'murano-api %(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s';
    'database/connection'                   : value => $api_database_connection;
    'database/auto_create'                  : value => $api_database_auto_create;
    'reports/results_exchange'              : value => $api_reports_results_exchange;
    'reports/results_queue'                 : value => $api_reports_results_queue;
    'reports/reports_exchange'              : value => $api_reports_reports_exchange;
    'reports/reports_queue'                 : value => $api_reports_reports_queue;
    'rabbitmq/host'                         : value => $api_rabbit_host;
    'rabbitmq/port'                         : value => $api_rabbit_port;
    'rabbitmq/ssl'                          : value => $api_rabbit_ssl;
    'rabbitmq/ca_certs'                     : value => $api_rabbit_ca_certs;
    'rabbitmq/login'                        : value => $api_rabbit_login;
    'rabbitmq/password'                     : value => $api_rabbit_password;
    'rabbitmq/virtual_host'                 : value => $api_rabbit_virtual_host;
    'keystone_authtoken/auth_host'          : value => $api_paste_auth_host;
    'keystone_authtoken/auth_port'          : value => $api_paste_auth_port;
    'keystone_authtoken/auth_protocol'      : value => $api_paste_auth_protocol;
    'keystone_authtoken/admin_tenant_name'  : value => $api_paste_admin_tenant_name;
    'keystone_authtoken/admin_user'         : value => $api_paste_admin_user;
    'keystone_authtoken/admin_password'     : value => $api_paste_admin_password;
    'keystone_authtoken/signing_dir'        : value => $api_paste_signing_dir;
  }

  murano_api_paste_ini_config {
    'pipeline:muranoapi/pipeline'           : value => $api_paste_inipipeline;
    'app:apiv1app/paste.app_factory'        : value => $api_paste_app_factory;
    'filter:context/paste.filter_factory'   : value => $api_paste_filter_factory;
    'filter:authtoken/paste.filter_factory' : value => $api_paste_paste_filter_factory;
  }

  firewall { $firewall_rule_name :
    dport   => [ $api_bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  File['murano-api-logging.conf'] ~> Service['murano_api']
  Murano_api_config<||> ~> Service['murano_api']
  Murano_api_paste_ini_config<||> ~> Service['murano_api']
  Package['murano_api'] -> Murano_api_config<||>
  Package['murano_api'] -> Murano_api_paste_ini_config<||>
  Package['murano_api'] -> Service['murano_api']

}
