class sahara (
  $sahara_enabled                      = true,
  $sahara_api_port                     = '8386',
  $sahara_api_host                     = '127.0.0.1',

  $sahara_auth_uri                     = 'http://127.0.0.1:5000/v2.0/',
  $sahara_identity_uri                 = 'http://127.0.0.1:35357/',
  $sahara_keystone_host                = '127.0.0.1',
  $sahara_keystone_user                = 'sahara',
  $sahara_keystone_tenant              = 'services',
  $sahara_keystone_password            = 'sahara',
  $sahara_node_domain                  = 'novalocal',

  $sahara_db_password                  = 'sahara',
  $sahara_db_name                      = 'sahara',
  $sahara_db_user                      = 'sahara',
  $sahara_db_host                      = 'localhost',
  $sahara_db_allowed_hosts             = ['localhost','%'],

  $sahara_firewall_rule                = '201 sahara-all',
  $use_neutron                         = false,

  $use_syslog                          = false,
  $debug                               = false,
  $verbose                             = false,
  $syslog_log_facility_sahara          = 'LOG_LOCAL0',

  $rpc_backend                         = false,
  $enable_notifications                = false,

  $amqp_password,
  $amqp_user                           = 'guest',
  $amqp_host                           = 'localhost',
  $amqp_port                           = '5672',
  $amqp_hosts                          = false,
  $rabbit_virtual_host                 = '/',
  $rabbit_ha_queues                    = false,
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
    sahara_auth_uri                     => $sahara_auth_uri,
    sahara_identity_uri                 => $sahara_identity_uri,
    keystone_user                       => $sahara_keystone_user,
    keystone_tenant                     => $sahara_keystone_tenant,
    keystone_password                   => $sahara_keystone_password,
    bind_port                           => $sahara_api_port,
    node_domain                         => $sahara_node_domain,
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

  if $enable_notifications {
    if $rpc_backend == 'rabbit' {
      class { 'sahara::notify::rabbitmq':
        rabbit_password      => $amqp_password,
        rabbit_userid        => $amqp_user,
        rabbit_host          => $amqp_host,
        rabbit_port          => $amqp_port,
        rabbit_hosts         => $amqp_hosts,
        rabbit_virtual_host  => $rabbit_virtual_host,
        rabbit_ha_queues     => $rabbit_ha_queues,
      }
    }

    if $rpc_backend == 'qpid' {
      class { 'sahara::notify::qpid':
        qpid_password  => $amqp_password,
        qpid_username  => $amqp_user,
        qpid_hostname  => $amqp_host,
        qpid_port      => $amqp_port,
        qpid_hosts     => $amqp_hosts,
      }
    }
  }

  firewall { $sahara_firewall_rule :
    dport   => $sahara_api_port,
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall']
  }

  #NOTE(mattymo): Backward compatibility for Icehouse
  case $::fuel_settings['openstack_version'] {
    /2014.1.*-6/: {
      class {'sahara::dashboard':
        enabled          => $sahara_enabled,
        use_neutron      => $use_neutron,
        use_floating_ips => $::fuel_settings['auto_assign_floating_ip'],
      }
      Class['sahara::api'] -> Class['sahara::dashboard']
    }
    default: { }
  }
  Class['mysql::server'] -> Class['sahara::db::mysql'] -> Firewall[$sahara_firewall_rule] -> Class['sahara::keystone::auth'] -> Class['sahara::api']

}
