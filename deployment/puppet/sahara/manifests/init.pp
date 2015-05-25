class sahara (
  $enabled                      = true,
  $api_port                     = '8386',
  $api_host                     = '127.0.0.1',

  $auth_uri                     = 'http://127.0.0.1:5000/v2.0/',
  $identity_uri                 = 'http://127.0.0.1:35357/',
  $keystone_host                = '127.0.0.1',
  $keystone_user                = 'sahara',
  $keystone_tenant              = 'services',
  $keystone_password            = 'sahara',
  $node_domain                  = 'novalocal',

  $db_password                  = 'sahara',
  $db_name                      = 'sahara',
  $db_user                      = 'sahara',
  $db_host                      = 'localhost',
  $db_allowed_hosts             = ['localhost','%'],

  $firewall_rule                = '201 sahara-api',
  $use_neutron                  = false,

  $use_syslog                   = false,
  $debug                        = false,
  $verbose                      = false,
  $syslog_log_facility          = 'LOG_LOCAL0',

  $rpc_backend                  = false,
  $enable_notifications         = false,

  $amqp_password,
  $amqp_user                    = 'guest',
  $amqp_host                    = 'localhost',
  $amqp_port                    = '5672',
  $amqp_hosts                   = false,
  $rabbit_virtual_host          = '/',
  $rabbit_ha_queues             = false,
) {

  $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?read_timeout=60"

  package { 'sahara-common':
    ensure => $package_ensure,
    name   => $::sahara::params::sahara_common_package_name,
  }

  class { 'sahara::db::mysql':
    password                     => $db_password,
    dbname                       => $db_name,
    user                         => $db_user,
    dbhost                       => $db_host,
    allowed_hosts                => $db_allowed_hosts,
  }

  class { 'sahara::api':
    enabled                      => $enabled,
    auth_uri                     => $auth_uri,
    identity_uri                 => $identity_uri,
    keystone_user                => $keystone_user,
    keystone_tenant              => $keystone_tenant,
    keystone_password            => $keystone_password,
    bind_port                    => $api_port,
    node_domain                  => $node_domain,
    sql_connection               => $sql_connection,
    use_neutron                  => $use_neutron,
    debug                        => $debug,
    use_syslog                   => $use_syslog,
    verbose                      => $verbose,
    syslog_log_facility          => $syslog_log_facility,
  }

  class { 'sahara::engine':
    enabled                      => $enabled,
    rpc_backend                  => $rpc_backend,
    amqp_password                => $amqp_password,
    amqp_user                    => $amqp_user,
    amqp_host                    => $amqp_host,
    amqp_port                    => $amqp_port,
    amqp_hosts                   => $amqp_hosts,
    rabbit_virtual_host          => $rabbit_virtual_host,
    rabbit_ha_queues             => $rabbit_ha_queues,
  }

  class { 'sahara::keystone::auth' :
    password                     => $keystone_password,
    auth_name                    => $keystone_user,
    public_address               => $api_host,
    admin_address                => $keystone_host,
    internal_address             => $keystone_host,
    sahara_port                  => $api_port,
    region                       => 'RegionOne',
    tenant                       => $keystone_tenant,
    email                        => 'sahara-team@localhost',
  }

  if $enable_notifications {
    if $rpc_backend == 'rabbit' {
      class { 'sahara::notify::rabbitmq':
        enable_notifications => true,
      }
    }

    if $rpc_backend == 'qpid' {
      class { 'sahara::notify::qpid':
      }
    }
  }

  firewall { $firewall_rule :
    dport   => $api_port,
    proto   => 'tcp',
    action  => 'accept',
  }

  Class['mysql::server'] ->
  Class['sahara::db::mysql'] ->
  Firewall[$firewall_rule] ->
  Package['sahara-common'] ->
  Class['sahara::keystone::auth'] ->
  Class['sahara::api'] ->
  Class['sahara::engine']

}
