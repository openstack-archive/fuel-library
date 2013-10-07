class murano::api (
    $enabled                        = true,
    $verbose                        = 'True',
    $debug                          = 'True',
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
    $api_database_auto_create       = 'True',
    $api_reports_results_exchange   = 'task-results',
    $api_reports_results_queue      = 'task-results',
    $api_reports_reports_exchange   = 'task-reports',
    $api_reports_reports_queue      = 'task-reports',
    $api_rabbit_host                = '127.0.0.1',
    $api_rabbit_port                = '5672',
    $api_rabbit_ssl                 = 'False',
    $api_rabbit_ca_certs            = '',
    $api_rabbit_login               = 'murano',
    $api_rabbit_password            = 'murano',
    $api_rabbit_virtual_host        = '/',

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

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'murano_api':
    ensure     => $service_ensure,
    name       => $::murano::params::murano_api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['murano_api'],
  }

  murano_api_config {
    'DEFAULT/verbose'                       : value => $verbose;
    'DEFAULT/debug'                         : value => $debug;
    'DEFAULT/bind_host'                     : value => $api_bind_host;
    'DEFAULT/bind_port'                     : value => $api_bind_port;
    'DEFAULT/log_file'                      : value => $api_log_file;
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
  }

  murano_api_paste_ini_config {
    'pipeline:muranoapi/pipeline'           : value => $api_paste_inipipeline;
    'app:apiv1app/paste.app_factory'        : value => $api_paste_app_factory;
    'filter:context/paste.filter_factory'   : value => $api_paste_filter_factory;
    'filter:authtoken/paste.filter_factory' : value => $api_paste_paste_filter_factory;
    'filter:authtoken/auth_host'            : value => $api_paste_auth_host;
    'filter:authtoken/auth_port'            : value => $api_paste_auth_port;
    'filter:authtoken/auth_protocol'        : value => $api_paste_auth_protocol;
    'filter:authtoken/admin_tenant_name'    : value => $api_paste_admin_tenant_name;
    'filter:authtoken/admin_user'           : value => $api_paste_admin_user;
    'filter:authtoken/admin_password'       : value => $api_paste_admin_password;
    'filter:authtoken/signing_dir'          : value => $api_paste_signing_dir;
  }

  Murano_api_config<||> ~> Service['murano_api']
  Murano_api_paste_ini_config<||> ~> Service['murano_api']
  Package['murano_api'] -> Murano_api_config<||>
  Package['murano_api'] -> Murano_api_paste_ini_config<||>
  Package['murano_api'] -> Service['murano_api']

}
