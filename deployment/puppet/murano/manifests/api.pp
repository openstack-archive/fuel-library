class murano::api (
    $use_syslog                 = false,
    $syslog_log_facility        = 'LOG_LOCAL0',
    $verbose                    = false,
    $debug                      = false,
    $paste_inipipeline          = 'authtoken context apiv1app',
    $paste_app_factory          = 'muranoapi.api.v1.router:API.factory',
    $paste_filter_factory       = 'muranoapi.api.middleware.context:ContextMiddleware.factory',
    $paste_paste_filter_factory = 'keystoneclient.middleware.auth_token:filter_factory',
    $auth_host                  = '127.0.0.1',
    $auth_port                  = '35357',
    $auth_protocol              = 'http',
    $admin_tenant_name          = 'admin',
    $admin_user                 = 'admin',
    $admin_password             = 'admin',
    $signing_dir                = '/tmp/keystone-signing-muranoapi',
    $bind_host                  = '0.0.0.0',
    $bind_port                  = '8082',
    $log_file                   = '/var/log/murano/murano.log',
    $rabbit_host                = '127.0.0.1',
    $rabbit_port                = '5672',
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
) {

  $database_connection = "mysql://${murano_db_name}:${murano_db_password}@${murano_db_host}:3306/${murano_db_name}?read_timeout=60"

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

  if $use_syslog and !$debug { #syslog and nondebug case
    murano_config {
      'DEFAULT/use_syslog'           : value => true;
      'DEFAULT/use_syslog_rfc_format': value => true;
      'DEFAULT/syslog_log_facility'  : value => $syslog_log_facility;
    }
  } else { #other syslog debug or nonsyslog debug/nondebug cases
    murano_config {
      'DEFAULT/log_file'  : value  => $api_log_file;
      'DEFAULT/use_syslog': value  => false;
    }
  }

  murano_config {
    'DEFAULT/verbose'                       : value => $verbose;
    'DEFAULT/debug'                         : value => $debug;
    'DEFAULT/bind_host'                     : value => $bind_host;
    'DEFAULT/bind_port'                     : value => $bind_port;

    'DEFAULT/rabbit_host'                   : value => $rabbit_host;
    'DEFAULT/rabbit_port'                   : value => $rabbit_port;
    'DEFAULT/rabbit_use_ssl'                : value => $rabbit_use_ssl;
    'DEFAULT/rabbit_userid'                 : value => $rabbit_login;
    'DEFAULT/rabbit_password'               : value => $rabbit_password;
    'DEFAULT/rabbit_virtual_host'           : value => $rabbit_virtual_host;

    'DEFAULT/kombu_ssl_ca_certs'            : value => $rabbit_ca_certs;

    'database/connection'                   : value => $database_connection;

    'keystone_authtoken/auth_host'          : value => $auth_host;
    'keystone_authtoken/auth_port'          : value => $auth_port;
    'keystone_authtoken/auth_protocol'      : value => $auth_protocol;
    'keystone_authtoken/admin_tenant_name'  : value => $admin_tenant_name;
    'keystone_authtoken/admin_user'         : value => $admin_user;
    'keystone_authtoken/admin_password'     : value => $admin_password;
    'keystone_authtoken/signing_dir'        : value => $signing_dir;
  }

  murano_paste_ini_config {
    'pipeline:muranoapi/pipeline'           : value => $paste_inipipeline;
    'app:apiv1app/paste.app_factory'        : value => $paste_app_factory;
    'filter:context/paste.filter_factory'   : value => $paste_filter_factory;
    'filter:authtoken/paste.filter_factory' : value => $paste_paste_filter_factory;
  }

  firewall { $firewall_rule_name :
    dport   => [ $api_bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  exec { 'murano_manage_db_sync':
    command => "murano-manage --config-file=/etc/murano/murano.conf db-sync",
    user    => $murano_user,
    group   => $murano_user,
  }

  Package['murano'] -> Murano_paste_ini_config<||> -> Murano_config<||> -> Exec['murano_manage_db_sync']

  #Package['murano'] -> Service['murano_api']
  Murano_config<||> ~> Service['murano_api']
  Murano_paste_ini_config<||> ~> Service['murano_api']
  Exec['murano_manage_db_sync'] ~> Service['murano_api']

  #Package['murano'] -> Service['murano_engine']
  Murano_config<||> ~> Service['murano_engine']
  Murano_paste_ini_config<||> ~> Service['murano_engine']
  Exec['murano_manage_db_sync'] ~> Service['murano_engine']

}
