$nova_hash = hiera('nova_hash')
$nova_db_password = $nova_hash['db_password']
$rabbit_hash     = hiera('rabbit_hash',
    {
      'user'     => false,
      'password' => false,
    }
  )
$internal_address = hiera('internal_address')
$memcache_servers = hiera('controller_nodes', [ $internal_address ])
$memcache_server_port = '11211'
$memcached_addresses = suffix($memcache_servers, inline_template(":<%= @memcache_server_port %>"))


if (hiera('deployment_mode') == 'ha') or (hiera('deployment_mode') == 'ha_compact') {
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

class { 'mysql::config' :
  bind_address       => $internal_address,
  use_syslog         => hiera('use_syslog'),
  custom_setup_class => hiera('deployment_mode')? {
                         ha => 'galera',
                         ha_compact => 'galera',
                         default => undef
			},
  config_file        => {
    'config_file' => '/etc/my.cnf'
  },
}

class { 'nova::db::mysql':
    user          => 'nova',
    password      => $nova_hash['db_password'],
    dbname        => 'nova',
    allowed_hosts => [ '%', $::hostname ],
  }
Class['nova::db::mysql'] -> Class['::nova']

  # From legacy ceilometer notifications for nova
  $notify_on_state_change = 'vm_and_task_state'
  $notification_driver = 'messaging'

  class { 'nova':
    install_utilities      => false,
    sql_connection         => "mysql://nova:${nova_db_password}@${db_host}/nova?read_timeout=60",
    rpc_backend            => 'nova.openstack.common.rpc.impl_kombu',
    #FIXME(bogdando) we have to split amqp_hosts until all modules synced
    rabbit_password     => $rabbit_hash['password'],
    rabbit_userid       => $rabbit_hash['user'],
    rabbit_hosts        => split( hiera('amqp_hosts'), ','),
    image_service          => 'nova.image.glance.GlanceImageService',
    glance_api_servers     => "${endpoint_public_address}:9292",
    verbose             => hiera('verbose'),
    debug               => hiera('debug'),
    ensure_package         => installed,
    log_facility           => hiera('syslog_log_facility_nova'),
    use_syslog             => hiera('use_syslog'),
    database_idle_timeout  => $idle_timeout,
    report_interval        => $nova_report_interval,
    service_down_time      => $nova_service_down_time,
    notify_on_state_change => $notify_on_state_change,
    notification_driver    => $notification_driver,
    memcached_servers      => $memcached_addresses,
  }

  #NOTE(bogdando) exec update-kombu is always undef, so delete?
  if (defined(Exec['update-kombu']))
  {
    Exec['update-kombu'] -> Nova::Generic_service<||>
  }

  if $use_syslog {
    nova_config {
      'DEFAULT/use_syslog_rfc_format':  value => true;
    }
  }

  nova_config {
    'DATABASE/max_pool_size': value => $max_pool_size;
    'DATABASE/max_retries':   value => $max_retries;
    'DATABASE/max_overflow':  value => $max_overflow;
  }

if (hiera('nova_quota')) {
    $nova_quota_driver = "nova.quota.DbQuotaDriver"
  } else {
    $nova_quota_driver = "nova.quota.NoopQuotaDriver"
  }


  class {'nova::quota':
    quota_instances                       => 100,
    quota_cores                           => 100,
    quota_volumes                         => 100,
    quota_gigabytes                       => 1000,
    quota_floating_ips                    => 100,
    quota_metadata_items                  => 1024,
    quota_max_injected_files              => 50,
    quota_max_injected_file_content_bytes => 102400,
    quota_max_injected_file_path_bytes    => 4096,
    quota_driver                          => $nova_quota_driver
  }

  if !(hiera('use_neutron')) {
    # Configure nova-network
    if (hiera('multi_host')) {
      nova_config { 'DEFAULT/multi_host': value => 'True' }
      $_enabled_apis = 'ec2,osapi_compute'
    } else {
      $_enabled_apis = "ec2,osapi_compute,metadata"
    }
  }

 $default_limits = {
    'POST' => 10,
    'POST_SERVERS' => 50,
    'PUT' => 10,
    'GET' => 3,
    'DELETE' => 100,
  }

  $merged_limits = merge($default_limits, hiera('nova_rate_limits'))
  $post_limit=$merged_limits[POST]
  $put_limit=$merged_limits[PUT]
  $get_limit=$merged_limits[GET]
  $delete_limit=$merged_limits[DELETE]
  $post_servers_limit=$merged_limits[POST_SERVERS]
  $nova_rate_limits_string = inline_template('<%="(POST, *, .*,  #{@post_limit} , MINUTE);\
(POST, %(*/servers), ^/servers,  #{@post_servers_limit} , DAY);(PUT, %(*) , .*,  #{@put_limit}\
 , MINUTE);(GET, %(*changes-since*), .*changes-since.*, #{@get_limit}, MINUTE);(DELETE, %(*),\
 .*, #{@delete_limit} , MINUTE)" %>')
  notice("will apply following limits: ${nova_rate_limits_string}")
  # Configure nova-api

  $keystone_host = hiera('management_vip')

  class { '::nova::api':
    enabled                              => true,
    api_bind_address                     => $internal_address,
    admin_password                       => $nova_hash['user_password'],
    auth_host                            => $keystone_host,
    enabled_apis                         => $_enabled_apis,
    ensure_package                       => installed,
    ratelimits                           => $nova_rate_limits_string,
    neutron_metadata_proxy_shared_secret => hiera('neutron_metadata_proxy_secret'),
    require                              => Package['nova-common'],
    osapi_compute_workers                => min($::processorcount + 0, 50 + 0),
  }

  nova_config {
    'DEFAULT/allow_resize_to_same_host':  value => true;
    'DEFAULT/api_paste_config':           value => '/etc/nova/api-paste.ini';
    'DEFAULT/keystone_ec2_url':           value => "http://${keystone_host}:5000/v2.0/ec2tokens";
    'keystone_authtoken/signing_dir':     value => '/tmp/keystone-signing-nova';
    'keystone_authtoken/signing_dirname': value => '/tmp/keystone-signing-nova';
  }

  nova_paste_api_ini {
    'filter:authtoken/signing_dir':       ensure => absent;
    'filter:authtoken/signing_dirname':   ensure => absent;
  }

  class {'::nova::conductor':
    enabled => true,
    ensure_package => installed,
  }

  if (hiera('auto_assign_floating_ip')) {
    nova_config { 'DEFAULT/auto_assign_floating_ip': value => 'True' }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::cert',
  ]:
    enabled => true,
    ensure_package => installed
  }

  class { '::nova::consoleauth':
    enabled        => true,
    ensure_package => installed,
  }

  class { 'nova::vncproxy':
    host           => $internal_address,
    enabled        => true,
    ensure_package => installed
  }

if (hiera('deployment_mode') == 'ha') or (hiera('deployment_mode') == 'ha_compact') {
  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  Cluster::Haproxy_service {
    server_names           => hiera('controller_hostnames'),
    ipaddresses            => hiera('controller_nodes'),
    public_virtual_ip      => hiera('public_vip'),
    internal_virtual_ip    => hiera('management_vip'),
  }

  cluster::haproxy_service { 'nova-api-1':
    order           => '040',
    listen_port     => 8773,
    public          => true,
  }

  cluster::haproxy_service { 'nova-api-2':
    order                  => '050',
    listen_port            => 8774,
    public                 => true,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  cluster::haproxy_service { 'nova-metadata-api':
    order                  => '060',
    listen_port            => 8775,
    haproxy_config_options => {
        option => ['httpchk', 'httplog','httpclose'],
    },
    balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
  }

  cluster::haproxy_service { 'nova-novncproxy':
    order           => '170',
    listen_port     => 6080,
    public          => true,
    internal        => false,
    require_service => 'nova-vncproxy',
  }

  Service['nova-api'] -> Cluster::Haproxy_service[ 'nova-api-1', 'nova-api-2', 'nova-metadata-api' ]
}

include nova::client

class { 'nova::keystone::auth':
        password         => $nova_hash['user_password'],
        public_address   => $endpoint_public_address,
        admin_address    => $endpoint_admin_address,
        internal_address => $endpoint_int_address,
        cinder           => true,
}
