class murano (
  # keystone
  $murano_keystone_host                 = '127.0.0.1',
  $murano_keystone_port                 = '5000',
  $murano_keystone_protocol             = 'http',
  $murano_keystone_tenant               = 'admin',
  $murano_keystone_user                 = 'admin',
  $murano_keystone_password             = 'admin',
  # murano
  $murano_log_file                      = '/var/log/murano/conductor.log',
  $murano_debug                         = 'True',
  $murano_verbose                       = 'True',
  $murano_data_dir                      = '/etc/murano',
  $murano_max_environments              = '20',
  $murano_api_host                      = '127.0.0.1',
  # rabbit
  $murano_rabbit_host                   = '127.0.0.1',
  $murano_rabbit_port                   = '55572',
  $murano_rabbit_ssl                    = 'False',
  $murano_rabbit_ca_certs               = '',
  $murano_rabbit_login                  = 'murano',
  $murano_rabbit_password               = 'murano',
  $murano_rabbit_virtual_host           = '/',
  # murano-api-paste.ini
  $murano_api_paste_inipipeline          = 'authtoken context apiv1app',
  $murano_api_paste_app_factory          = 'muranoapi.api.v1.router:API.factory',
  $murano_api_paste_filter_factory       = 'muranoapi.api.middleware.context:ContextMiddleware.factory',
  $murano_api_paste_paste_filter_factory = 'keystoneclient.middleware.auth_token:filter_factory',
  $murano_api_paste_signing_dir          = '/tmp/keystone-signing-muranoapi',
  # murano-api.conf
  $murano_api_bind_host                 = '0.0.0.0',
  $murano_api_bind_port                 = '8082',
  $murano_api_log_file                  = '/var/log/murano/murano-api.log',
  $murano_api_database_auto_create      = 'True',
  $murano_api_reports_results_exchange  = 'task-results',
  $murano_api_reports_results_queue     = 'task-results',
  $murano_api_reports_reports_exchange  = 'task-reports',
  $murano_api_reports_reports_queue     = 'task-reports',
  # mysql
  $murano_db_password                   = 'murano',
  $murano_db_name                       = 'murano',
  $murano_db_user                       = 'murano',
  $murano_db_host                       = 'localhost',
  $murano_db_allowed_hosts              = ['localhost','%'],
) {

  $murano_keystone_auth_url = "${murano_keystone_protocol}://${murano_keystone_host}:${murano_keystone_port}/v2.0"

  class { 'murano::db::mysql':
    password                             => $murano_db_password,
    dbname                               => $murano_db_name,
    user                                 => $murano_db_user,
    dbhost                               => $murano_db_host,
    allowed_hosts                        => $murano_db_allowed_hosts,
  }

  class { 'murano::conductor' :
    debug                                => $murano_debug,
    verbose                              => $murano_verbose,
    log_file                             => $murano_log_file,
    data_dir                             => $murano_data_dir,
    max_environments                     => $murano_max_environments,
    auth_url                             => $murano_keystone_auth_url,

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
    api_paste_auth_host                  => $murano_keystone_host,
    api_paste_auth_port                  => $murano_keystone_port,
    api_paste_auth_protocol              => $murano_keystone_protocol,
    api_paste_admin_tenant_name          => $murano_keystone_tenant,
    api_paste_admin_user                 => $murano_keystone_user,
    api_paste_admin_password             => $murano_keystone_password,
    api_paste_signing_dir                => $murano_api_paste_signing_dir,
    api_bind_host                        => $murano_api_bind_host,
    api_bind_port                        => $murano_api_bind_port,
    api_log_file                         => $murano_api_log_file,
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

    murano_db_password                   => $murano_db_password,
    murano_db_name                       => $murano_db_name,
    murano_db_user                       => $murano_db_user,
    murano_db_host                       => $murano_db_host,
  }

  class { 'murano::dashboard' :
    settings_py           => '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
    collect_static_script => '/usr/share/openstack-dashboard/manage.py',
    murano_url_string     => "MURANO_API_URL = 'http://${murano_api_host}:${murano_api_bind_port}'",
  }

  class { 'murano::rabbitmq' :
    rabbit_user        => $murano_rabbit_login,
    rabbit_password    => $murano_rabbit_password,
    rabbit_vhost       => $murano_rabbit_virtual_host,
    rabbitmq_main_port => $murano_rabbit_port,
  }

  Class['mysql::server'] -> Class['murano::db::mysql'] -> Class['murano::rabbitmq'] -> Class['murano::conductor'] -> Class['murano::api'] -> Class['murano::dashboard']

}
