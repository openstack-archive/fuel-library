class murano (
  # murano
  $murano_enabled                       = true,
  $murano_log_file                      = '/var/log/murano/conductor.log',
  $murano_debug                         = 'True',
  $murano_verbose                       = 'True',
  $murano_data_dir                      = '/etc/murano',
  $murano_max_environments              = '20',
  $murano_heat_auth_url                 = 'http://127.0.0.1:5000/v2.0',
  # rabbit
  $murano_rabbit_host                   = '127.0.0.1',
  $murano_rabbit_port                   = '5672',
  $murano_rabbit_ssl                    = 'False',
  $murano_rabbit_ca_certs               = '',
  $murano_rabbit_login                  = 'nova',
  $murano_rabbit_password               = 'nova1',
  $murano_rabbit_virtual_host           = '/',
  # murano-api-paste.ini
  $murano_api_paste_inipipeline          = 'authtoken context apiv1app',
  $murano_api_paste_app_factory          = 'muranoapi.api.v1.router:API.factory',
  $murano_api_paste_filter_factory       = 'muranoapi.api.middleware.context:ContextMiddleware.factory',
  $murano_api_paste_paste_filter_factory = 'keystoneclient.middleware.auth_token:filter_factory',
  $murano_api_paste_auth_host            = '192.168.1.2',
  $murano_api_paste_auth_port            = '35357',
  $murano_api_paste_auth_protocol        = 'http',
  $murano_api_paste_admin_tenant_name    = 'admin',
  $murano_api_paste_admin_user           = 'admin',
  $murano_api_paste_admin_password       = 'admin',
  $murano_api_paste_signing_dir          = '/tmp/keystone-signing-muranoapi',
  # murano-api.conf
  $murano_api_bind_host                 = '0.0.0.0',
  $murano_api_bind_port                 = '8082',
  $murano_api_log_file                  = '/var/log/murano/murano-api.log',
  $murano_api_database_connection       = 'mysql://murano:murano@localhost:3306/murano',
  $murano_api_database_auto_create      = 'True',
  $murano_api_reports_results_exchange  = 'task-results',
  $murano_api_reports_results_queue     = 'task-results',
  $murano_api_reports_reports_exchange  = 'task-reports',
  $murano_api_reports_reports_queue     = 'task-reports',
  $murano_db_password                   = 'murano',
  $murano_db_name                       = 'murano',
  $murano_db_user                       = 'murano',
  $murano_db_password                   = 'murano',
  $murano_db_name                       = 'murano',
  $murano_db_user                       = 'murano',

) {

  class { 'murano::db::mysql':
    password                            => $murano_db_password,
    dbname                              => $murano_db_name,
    user                                => $murano_db_user,
  }

  class { 'murano::conductor' :
    enabled                              => $murano_enabled,
    log_file                             => $murano_log_file,
    debug                                => $murano_debug,
    verbose                              => $murano_verbose,
    data_dir                             => $murano_data_dir,
    max_environments                     => $murano_max_environments,
    heat_auth_url                        => $murano_heat_auth_url,

    rabbit_host                          => $murano_rabbit_host,
    rabbit_port                          => $murano_rabbit_port,
    rabbit_ssl                           => $murano_rabbit_ssl,
    rabbit_ca_certs                      => $murano_rabbit_ca_certs,
    rabbit_login                         => $murano_rabbit_login,
    rabbit_password                      => $murano_rabbit_password,
    rabbit_virtual_host                  => $murano_rabbit_virtual_host,
  }

  class { 'murano::api' :
    debug                                => $murano_debug,
    verbose                              => $murano_verbose,
    api_paste_inipipeline                => $murano_api_paste_inipipeline,
    api_paste_app_factory                => $murano_api_paste_app_factory,
    api_paste_filter_factory             => $murano_api_paste_filter_factory,
    api_paste_paste_filter_factory       => $murano_api_paste_paste_filter_factory,
    api_paste_auth_host                  => $murano_api_paste_auth_host,
    api_paste_auth_port                  => $murano_api_paste_auth_port,
    api_paste_auth_protocol              => $murano_api_paste_auth_protocol,
    api_paste_admin_tenant_name          => $murano_api_paste_admin_tenant_name,
    api_paste_admin_user                 => $murano_api_paste_admin_user,
    api_paste_admin_password             => $murano_api_paste_admin_password,
    api_paste_signing_dir                => $murano_api_paste_signing_dir,
    api_bind_host                        => $murano_api_bind_host,
    api_bind_port                        => $murano_api_bind_port,
    api_log_file                         => $murano_api_log_file,
    api_database_connection              => $murano_api_database_connection,
    api_database_auto_create             => $murano_api_database_auto_create,
    api_reports_results_exchange         => $murano_api_reports_results_exchange,
    api_reports_results_queue            => $murano_api_reports_results_queue,
    api_reports_reports_exchange         => $murano_api_reports_reports_exchange,
    api_reports_reports_queue            => $murano_api_reports_reports_queue,

    api_rabbit_host                      => $murano_rabbit_host,
    api_rabbit_port                      => $murano_rabbit_port,
    api_rabbit_ssl                       => $murano_rabbit_ssl,
    api_rabbit_ca_certs                  => $murano_rabbit_ca_certs,
    api_rabbit_login                     => $murano_rabbit_login,
    api_rabbit_password                  => $murano_rabbit_password,
    api_rabbit_virtual_host              => $murano_rabbit_virtual_host,
  }

  class { 'murano::dashboard' :
    enabled              => $murano_enabled,
    settings_py          => '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
    collectstatic_script => '/usr/share/openstack-dashboard/manage.py',

  }

  class { 'murano::rabbitmq' :
    rabbit_user        => $murano_rabbit_login,
    rabbit_password    => $murano_rabbit_password,
    rabbit_vhost       => $murano_rabbit_virtual_host,
    rabbitmq_main_port => $murano_rabbit_port,
  }

  Class['mysql::server']  ->   Class['murano::db::mysql'] ->  Class['murano::rabbitmq'] -> Class['murano::conductor'] -> Class['murano::api'] -> Class['murano::dashboard']

}
