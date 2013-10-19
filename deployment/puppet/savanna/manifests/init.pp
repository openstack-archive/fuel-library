class savanna (
  $savanna_enabled                      = true,
  $savanna_api_port                     = '8386',
  $savanna_api_host                     = '127.0.0.1',
  $savanna_api_protocol                 = 'http',
  $savanna_api_version                  = 'v1.0',
  $savanna_keystone_host                = '127.0.0.1',
  $savanna_keystone_port                = '35357',
  $savanna_keystone_protocol            = 'http',
  $savanna_keystone_user                = 'admin',
  $savanna_keystone_tenant              = 'admin',
  $savanna_keystone_password            = 'admin',
  $savanna_node_domain                  = 'novalocal',
  $savanna_plugins                      = 'vanilla,hdp',
  $savanna_vanilla_plugin_class         = 'savanna.plugins.vanilla.plugin:VanillaProvider',
  $savanna_hdp_plugin_class             = 'savanna.plugins.hdp.ambariplugin:AmbariPlugin',
  $savanna_db_password                  = 'savanna',
  $savanna_db_name                      = 'savanna',
  $savanna_db_user                      = 'savanna',
  $savanna_db_host                      = 'localhost',
  $savanna_db_allowed_hosts             = ['localhost','%'],
  $savanna_firewall_rule                = '201 savanna-api',
  $use_neutron                          = false,
) {

  $savanna_sql_connection               = "mysql://${savanna_db_user}:${savanna_db_password}@${savanna_db_host}/${savanna_db_name}"
  $savanna_url_string                   = "SAVANNA_URL = '${savanna_api_protocol}://${savanna_api_host}:${savanna_api_port}/${savanna_api_version}'"

  class { 'savanna::db::mysql':
    password                            => $savanna_db_password,
    dbname                              => $savanna_db_name,
    user                                => $savanna_db_user,
    dbhost                              => $savanna_db_host,
    allowed_hosts                       => $savanna_db_allowed_hosts,
  }

  class { 'savanna::api':
    enabled                             => $savanna_enabled,
    keystone_host                       => $savanna_keystone_host,
    keystone_port                       => $savanna_keystone_port,
    keystone_protocol                   => $savanna_keystone_protocol,
    keystone_user                       => $savanna_keystone_user,
    keystone_tenant                     => $savanna_keystone_tenant,
    keystone_password                   => $savanna_keystone_password,
    bind_port                           => $savanna_api_port,
    node_domain                         => $savanna_node_domain,
    plugins                             => $savanna_plugins,
    vanilla_plugin_class                => $savanna_vanilla_plugin_class,
    hdp_plugin_class                    => $savanna_hdp_plugin_class,
    sql_connection                      => $savanna_sql_connection,
    use_neutron                         => $use_neutron,
  }

  firewall { $savanna_firewall_rule :
    dport   => $savanna_api_port,
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall']
  }

  class { 'savanna::dashboard' :
    enabled            => $savanna_enabled,
    savanna_url_string => $savanna_url_string,
    use_neutron        => $use_neutron,
  }

  Class['mysql::server'] -> Class['savanna::db::mysql'] -> Firewall[$savanna_firewall_rule] -> Class['savanna::api'] -> Class['savanna::dashboard']

}
