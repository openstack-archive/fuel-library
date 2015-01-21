$keystone_hash = hiera('keystone_hash')
$db_password = $keystone_hash['db_password']
$rabbit_hash     = hiera('rabbit_hash',
    {
      'user'     => false,
      'password' => false,
    }
  )
$internal_address = hiera('internal_address')
$memcache_servers = hiera('controller_nodes', [ $internal_address ])
$memcache_server_port = '11211'
$token_driver = 'keystone.token.backends.memcache.Token'

if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
  $db_host = hiera('management_vip')
  $bind_host = $internal_address
  $endpoint_public_address   = hiera('public_vip')
  $endpoint_admin_address  = hiera('management_vip')
  $endpoint_int_address = hiera('management_vip')
} else {
  $db_host = '127.0.0.1'
  $bind_host = '0.0.0.0'
  $endpoint_public_address  = hiera('public_address')
  $endpoint_admin_address   = $internal_address
  $endpoint_int_address  = $internal_address
}

$memcache_servers_real = suffix($memcache_servers, inline_template(":<%= @memcache_server_port %>"))

  class { 'memcached':
    listen_ip => $internal_address,
  }

  if hiera('use_ceilometer') {
    $notification_driver = 'messaging'
    $notification_topics = 'notifications'
  } else {
    $notification_driver = false
    $notification_topics = false
  }

  class { '::keystone':
    verbose             => hiera('verbose'),
    debug               => hiera('debug'),
    catalog_type        => 'sql',
    admin_token         => $keystone_hash['admin_token'],
    enabled             => true,
    sql_connection      => "mysql://keystone:${db_password}@${db_host}/keystone?read_timeout=60",
    bind_host           => $bind_host,
    package_ensure      => present,
    use_syslog          => hiera('use_syslog'),
    idle_timeout        => $idle_timeout,
    rabbit_password     => $rabbit_hash['password'],
    rabbit_userid       => $rabbit_hash['user'],
    rabbit_hosts        => split( hiera('amqp_hosts'), ','),
    rabbit_virtual_host => '/',
    memcache_servers    => $memcache_servers_real,
    token_driver        => $token_driver,
    token_provider      => 'keystone.token.providers.uuid.Provider',
    notification_driver => $notification_driver,
    notification_topics => $notification_topics,
  }

  Service<| title == 'memcached' |> -> Service<| title == 'keystone'|>
  keystone_config {
    'token/caching':                      value => 'false';
    'cache/enabled':                      value => 'true';
    'cache/backend':                      value => 'keystone.cache.memcache_pool';
    'cache/memcache_servers':             value => join($memcache_servers_real, ',');
    'cache/memcache_dead_retry':          value => '300';
    'cache/memcache_socket_timeout':      value => '3';
    'cache/memcache_pool_maxsize':        value => '100';
    'cache/memcache_pool_unused_timeout': value => '60';
  }

  Package<| title == 'keystone'|> ~> Service<| title == 'keystone'|>

  if hiera('use_syslog') {
    keystone_config {
      'DEFAULT/use_syslog_rfc_format':  value  => true;
    }
  }

  keystone_config {
    'DATABASE/max_pool_size':                          value => hiera('max_pool_size');
    'DATABASE/max_retries':                            value => hiera('max_retries');
    'DATABASE/max_overflow':                           value => hiera('max_overflow');
    'identity/driver':                                 value =>"keystone.identity.backends.sql.Identity";
    'policy/driver':                                   value =>"keystone.policy.backends.rules.Policy";
    'ec2/driver':                                      value =>"keystone.contrib.ec2.backends.sql.Ec2";
    'filter:debug/paste.filter_factory':               value =>"keystone.common.wsgi:Debug.factory";
    'filter:token_auth/paste.filter_factory':          value =>"keystone.middleware:TokenAuthMiddleware.factory";
    'filter:admin_token_auth/paste.filter_factory':    value =>"keystone.middleware:AdminTokenAuthMiddleware.factory";
    'filter:xml_body/paste.filter_factory':            value =>"keystone.middleware:XmlBodyMiddleware.factory";
    'filter:json_body/paste.filter_factory':           value =>"keystone.middleware:JsonBodyMiddleware.factory";
    'filter:user_crud_extension/paste.filter_factory': value =>"keystone.contrib.user_crud:CrudExtension.factory";
    'filter:crud_extension/paste.filter_factory':      value =>"keystone.contrib.admin_crud:CrudExtension.factory";
    'filter:ec2_extension/paste.filter_factory':       value =>"keystone.contrib.ec2:Ec2Extension.factory";
    'filter:s3_extension/paste.filter_factory':        value =>"keystone.contrib.s3:S3Extension.factory";
    'filter:url_normalize/paste.filter_factory':       value =>"keystone.middleware:NormalizingFilter.factory";
    'filter:stats_monitoring/paste.filter_factory':    value =>"keystone.contrib.stats:StatsMiddleware.factory";
    'filter:stats_reporting/paste.filter_factory':     value =>"keystone.contrib.stats:StatsExtension.factory";
    'app:public_service/paste.app_factory':            value =>"keystone.service:public_app_factory";
    'app:admin_service/paste.app_factory':             value =>"keystone.service:admin_app_factory";
    'pipeline:public_api/pipeline':                    value =>"stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug ec2_extension user_crud_extension public_service";
    'pipeline:admin_api/pipeline':                     value =>"stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug stats_reporting ec2_extension s3_extension crud_extension admin_service";
    'app:public_version_service/paste.app_factory':    value =>"keystone.service:public_version_app_factory";
    'app:admin_version_service/paste.app_factory':     value =>"keystone.service:admin_version_app_factory";
    'pipeline:public_version_api/pipeline':            value =>"stats_monitoring url_normalize xml_body public_version_service";
    'pipeline:admin_version_api/pipeline':             value =>"stats_monitoring url_normalize xml_body admin_version_service";
    'composite:main/use':                              value =>"egg:Paste#urlmap";
    'composite:main//v2.0':                            value =>"public_api";
    'composite:main//':                                value =>"public_version_api";
    'composite:admin/use':                             value =>"egg:Paste#urlmap";
    'composite:admin//v2.0':                           value =>"admin_api";
    'composite:admin//':                               value =>"admin_version_api";
  }

  # Setup the admin user
  class { 'keystone::roles::admin':
    admin        => $admin_user,
    email        => $admin_email,
    password     => $admin_password,
    admin_tenant => $admin_tenant,
  }
  Exec <| title == 'keystone-manage db_sync' |> -> Class['keystone::roles::admin']

  # Setup the Keystone Identity Endpoint
  class { 'keystone::endpoint':
    public_address   => $endpoint_public_address,
    admin_address    => $endpoint_admin_address,
    internal_address => $endpoint_int_address,
  }
  Exec <| title == 'keystone-manage db_sync' |> -> Class['keystone::endpoint']

  class { 'mysql::config' :
    bind_address       => $internal_address,
    use_syslog         => hiera('use_syslog'),
    custom_setup_class => 'galera',
    config_file        => {
      'config_file' => '/etc/my.cnf'
    },
  }

  class { 'keystone::db::mysql':
    user          => 'keystone',
    password      => $keystone_hash['db_password'],
    dbname        => 'keystone',
    allowed_hosts => [ '%', $::hostname ],
  }

  Class['keystone::db::mysql'] -> Class['::keystone']

if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  cluster::haproxy_service { 'keystone-1':
    server_names           => hiera('controller_hostnames'),
    ipaddresses            => hiera('controller_nodes'),
    public_virtual_ip      => hiera('public_vip'),
    internal_virtual_ip    => hiera('management_vip'),
    order                  => '020',
    listen_port            => 5000,
    public                 => true,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  cluster::haproxy_service { 'keystone-2':
    server_names           => hiera('controller_hostnames'),
    ipaddresses            => hiera('controller_nodes'),
    public_virtual_ip      => hiera('public_vip'),
    internal_virtual_ip    => hiera('management_vip'),
    order                  => '030',
    listen_port            => 35357,
    public                 => true,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3'
  }

  Service <| title=='keystone' |> -> Cluster::Haproxy_service['keystone-1', 'keystone-2']

}
