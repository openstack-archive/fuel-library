class sahara (
  $sahara_enabled                      = true,
  $sahara_api_port                     = '8386',
  $sahara_api_host                     = '127.0.0.1',
  $sahara_api_version                  = 'v1.1',

  $sahara_keystone_host                = '127.0.0.1',
  $sahara_keystone_port                = '35357',
  $sahara_keystone_protocol            = 'http',
  $sahara_keystone_user                = 'sahara',
  $sahara_keystone_tenant              = 'services',
  $sahara_keystone_password            = 'sahara',

  $sahara_node_domain                  = 'novalocal',
  $sahara_plugins                      = 'vanilla,hdp',

  $sahara_db_password                  = 'sahara',
  $sahara_db_name                      = 'sahara',
  $sahara_db_user                      = 'sahara',
  $sahara_db_host                      = 'localhost',
  $sahara_db_allowed_hosts             = ['localhost','%'],

  $sahara_firewall_rule                = '201 sahara-api',
  $use_neutron                         = false,
  $use_floating_ips                    = false,

  $use_syslog                          = false,
  $debug                               = false,
  $verbose                             = false,
  $syslog_log_facility_sahara          = 'LOG_LOCAL0',
) {

  $sahara_sql_connection               = "mysql://${sahara_db_user}:${sahara_db_password}@${sahara_db_host}/${sahara_db_name}?read_timeout=60"

  class { 'sahara::db::mysql':
    password                            => $sahara_db_password,
    dbname                              => $sahara_db_name,
    user                                => $sahara_db_user,
    dbhost                              => $sahara_db_host,
    allowed_hosts                       => $sahara_db_allowed_hosts,
  }

  class { 'sahara::api':
    enabled                             => $sahara_enabled,
    keystone_host                       => $sahara_keystone_host,
    keystone_port                       => $sahara_keystone_port,
    keystone_protocol                   => $sahara_keystone_protocol,
    keystone_user                       => $sahara_keystone_user,
    keystone_tenant                     => $sahara_keystone_tenant,
    keystone_password                   => $sahara_keystone_password,
    bind_port                           => $sahara_api_port,
    node_domain                         => $sahara_node_domain,
    plugins                             => $sahara_plugins,
    sql_connection                      => $sahara_sql_connection,
    use_neutron                         => $use_neutron,
    debug                               => $debug,
    use_syslog                          => $use_syslog,
    verbose                             => $verbose,
    syslog_log_facility_sahara          => $syslog_log_facility_sahara,
  }

  class { 'sahara::keystone::auth' :
    password                       => $sahara_keystone_password,
    auth_name                      => $sahara_keystone_user,
    public_address                 => $sahara_api_host,
    admin_address                  => $sahara_keystone_host,
    internal_address               => $sahara_keystone_host,
    sahara_port                    => $sahara_api_port,
    region                         => 'RegionOne',
    tenant                         => $sahara_keystone_tenant,
    email                          => 'sahara-team@localhost',
  }

  firewall { $sahara_firewall_rule :
    dport   => $sahara_api_port,
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall']
  }

  class { 'sahara::dashboard' :
    enabled            => $sahara_enabled,
    use_neutron        => $use_neutron,
    use_floating_ips   => $use_floating_ips,
  }

  Class['mysql::server'] -> Class['sahara::db::mysql'] -> Firewall[$sahara_firewall_rule] -> Class['sahara::keystone::auth'] -> Class['sahara::api'] -> Class['sahara::dashboard']

}
