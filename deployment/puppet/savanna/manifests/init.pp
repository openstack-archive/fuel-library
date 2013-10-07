class savanna (
  $savanna_enabled                      = true,
  $savanna_api_bind_port                = '8386',
  $savanna_keystone_host                = '127.0.0.1',
  $savanna_keystone_port                = '35357',
  $savanna_keystone_protocol            = 'http',
  $savanna_keystone_user                = 'admin',
  $savanna_keystone_tenant              = 'admin',
  $savanna_keystone_password            = 'admin',
  $savanna_use_floading_ips             = 'False',
  $savanna_node_domain                  = 'novalocal',
  $savanna_plugins                      = 'vanilla',
  $savanna_vanilla_plugin_plugin_class  = 'savanna.plugins.vanilla.plugin:VanillaProvider',
  $savanna_db_password                  = 'savanna',
  $savanna_db_name                      = 'savanna',
  $savanna_db_user                      = 'savanna',
) {

  $savanna_sql_connection               = "mysql://${$savanna_db_user}:${savanna_db_password}@localhost/${savanna_db_name}"

  class { 'savanna::db::mysql':
    password                            => $savanna_db_password,
    dbname                              => $savanna_db_name,
    user                                => $savanna_db_user,
  }

  class { 'savanna::api':
    enabled                             => $savanna_enabled,
    keystone_host                       => $savanna_keystone_host,
    keystone_port                       => $savanna_keystone_port,
    keystone_protocol                   => $savanna_keystone_protocol,
    keystone_user                       => $savanna_keystone_user,
    keystone_tenant                     => $savanna_keystone_tenant,
    keystone_password                   => $savanna_keystone_password,
    bind_port                           => $savanna_api_bind_port,
    use_floading_ips                    => $savanna_use_floading_ips,
    node_domain                         => $savanna_node_domain,
    plugins                             => $savanna_plugins,
    vanilla_plugin_plugin_class         => $savanna_vanilla_plugin_plugin_class,
    sql_connection                      => $savanna_sql_connection,
  }

  class { 'savanna::dashboard' :
    enabled            => $savanna_enabled,
    settings_py        => '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
    local_settings     => '/etc/openstack-dashboard/local_settings',
    savanna_url_string => "SAVANNA_URL = 'http://localhost:8386/v1.0'",
  }

  Class['mysql::server']  -> Class['savanna::db::mysql'] -> Class['savanna::api'] -> Class['savanna::dashboard']

}
