#
# == Class: openstack::nova::controller
#
# Class to define nova components used in a controller architecture.
# Basically everything but nova-compute and nova-volume
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack::nova::controller':
#   public_address       => '192.168.1.1',
#   db_host              => '127.0.0.1',
#   amqp_password        => 'changeme',
#   nova_user_password   => 'changeme',
#   nova_db_password     => 'changeme',
#   nova_api_db_password => 'changeme',
# }
#

class openstack::nova::controller (
  # Network Required
  $public_address,
  $public_interface,
  $private_interface,
  # Database Required
  $db_host,
  # Nova Required
  $nova_user_password,
  $nova_db_password,
  $nova_api_db_password,
  $nova_hash                            = {},
  $primary_controller                   = false,
  $ha_mode                              = false,
  # Network
  $fixed_range                          = '10.0.0.0/24',
  $floating_range                       = false,
  $internal_address,
  $admin_address,
  $service_endpoint                     = '127.0.0.1',
  $auto_assign_floating_ip              = false,
  $create_networks                      = true,
  $num_networks                         = 1,
  $network_size                         = 255,
  $multi_host                           = false,
  $network_config                       = {},
  $network_manager                      = 'nova.network.manager.FlatDHCPManager',
  $nova_quota_driver                    = 'nova.quota.NoopQuotaDriver',
  # Neutron
  $neutron                              = false,
  $segment_range                        = '1:4094',
  $tenant_network_type                  = 'gre',
  # Nova
  $nova_user                            = 'nova',
  $nova_user_tenant                     = 'services',
  $nova_db_user                         = 'nova',
  $nova_db_dbname                       = 'nova',
  $nova_api_db_user                     = 'nova_api',
  $nova_api_db_dbname                   = 'nova_api',
  # RPC
  # FIXME(bogdando) replace queue_provider for rpc_backend once all modules synced with upstream
  $rpc_backend                          = 'nova.openstack.common.rpc.impl_kombu',
  $queue_provider                       = 'rabbitmq',
  $amqp_hosts                           = ['127.0.0.1:5672'],
  $amqp_user                            = 'nova',
  $amqp_password                        = 'rabbit_pw',
  $rabbit_ha_queues                     = false,
  $rabbitmq_bind_ip_address             = 'UNSET',
  $rabbitmq_bind_port                   = '5672',
  $rabbitmq_cluster_nodes               = [],
  $cluster_partition_handling           = 'autoheal',
  # Database
  $db_type                              = 'mysql',
  # Glance
  $glance_api_servers                   = undef,
  # VNC
  $vnc_enabled                          = true,
  # General
  $keystone_auth_uri                    = 'http://127.0.0.1:5000/',
  $keystone_identity_uri                = 'http://127.0.0.1:35357/',
  $keystone_ec2_url                     = 'http://127.0.0.1:5000/v2.0/ec2tokens',
  $cache_server_ip                      = ['127.0.0.1'],
  $cache_server_port                    = '11211',
  $verbose                              = false,
  $debug                                = false,
  $default_log_levels                   = undef,
  $enabled                              = true,
  $exported_resources                   = true,
  $nameservers                          = undef,
  $ensure_package                       = present,
  $enabled_apis                         = 'ec2,osapi_compute',
  $api_bind_address                     = '0.0.0.0',
  $use_syslog                           = false,
  $use_stderr                           = true,
  $syslog_log_facility                  = 'LOG_LOCAL6',
  $syslog_log_facility_neutron          = 'LOG_LOCAL4',
  $nova_rate_limits                     = undef,
  $nova_report_interval                 = '10',
  $nova_service_down_time               = '60',
  $cinder                               = true,
  $ceilometer_notification_driver       = false,
  $service_workers                      = $::processorcount,
  # SQLAlchemy backend
  $idle_timeout                         = '3600',
  $max_pool_size                        = '10',
  $max_overflow                         = '30',
  $max_retries                          = '-1',
  $novnc_address                        = '127.0.0.1',
  $neutron_metadata_proxy_shared_secret = undef,
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      # TODO(aschultz): update this class to accept a connection string rather
      # than use host/user/pass/dbname/type
      # LP#1526938 - python-mysqldb supports this, python-pymysql does not
      if $::os_package_type == 'debian' {
        $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
      } else {
        $extra_params = { 'charset' => 'utf8' }
      }
      $db_connection = os_database_connection({
        'dialect'  => $db_type,
        'host'     => $db_host,
        'database' => $nova_db_dbname,
        'username' => $nova_db_user,
        'password' => $nova_db_password,
        'extra'    => $extra_params
      })
      $api_db_connection = os_database_connection({
        'dialect'  => $db_type,
        'host'     => $db_host,
        'database' => $nova_api_db_dbname,
        'username' => $nova_api_db_user,
        'password' => $nova_api_db_password,
        'extra'    => $extra_params
      })
    }
  }


  if ($glance_api_servers == undef) {
    $real_glance_api_servers = "${public_address}:9292"
  } else {
    $real_glance_api_servers = $glance_api_servers
  }

  $sql_connection    = $db_connection
  $glance_connection = $real_glance_api_servers

  if ($debug) {
    $rabbit_levels = '[connection,debug,info,error]'
  } else {
    $rabbit_levels = '[connection,info,error]'
  }

  # From legacy params.pp
  case $::osfamily {
    'RedHat': {
      $pymemcache_package_name      = 'python-memcached'
      $command_timeout              = "'-s KILL'"
      $package_provider             = 'yum'
    }
    'Debian': {
      $pymemcache_package_name      = 'python-memcache'
      $command_timeout              = "'--signal=KILL'"
      $package_provider             = 'apt'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem},\
 module ${module_name} only support osfamily RedHat and Debian")
    }
  }

  if $ha_mode {
    $rabbit_pid_file                   = '/var/run/rabbitmq/p_pid'
  } else {
    $rabbit_pid_file                   = '/var/run/rabbitmq/pid'
  }

  # Install / configure queue provider
  case $queue_provider {
    'rabbitmq': {
      notice("Rabbitmq server should be already installed and configured.")
    }
    'qpid': {
      class { 'qpid::server':
        auth              => 'yes',
        auth_realm        => 'QPID',
        log_to_file       => '/var/log/qpidd.log',
        cluster_mechanism => 'DIGEST-MD5',
        qpid_username     => $amqp_user,
        qpid_password     => $amqp_password,
        qpid_nodes        => [$internal_address],
      }
    }
  }

  $memcached_addresses =  suffix($cache_server_ip, inline_template(":<%= @cache_server_port %>"))

  # we can't use pick for this because pick blows up on []
  if $nova_hash['notification_driver'] {
    $nova_notification_driver = $nova_hash['notification_driver']
  } else {
    $nova_notification_driver = []
  }

  # From legacy ceilometer notifications for nova
  if ($ceilometer_notification_driver) {
    $notify_on_state_change = 'vm_and_task_state'
    $notification_driver = concat([$ceilometer_notification_driver], $nova_notification_driver)
  } else {
    $notification_driver = $nova_notification_driver
  }

  class { 'nova':
    install_utilities       => false,
    database_connection     => $sql_connection,
    api_database_connection => $api_db_connection,
    rpc_backend             => $rpc_backend,
    #FIXME(bogdando) we have to split amqp_hosts until all modules synced
    rabbit_hosts            => split($amqp_hosts, ','),
    rabbit_userid           => $amqp_user,
    rabbit_password         => $amqp_password,
    kombu_reconnect_delay   => '5.0',
    image_service           => 'nova.image.glance.GlanceImageService',
    glance_api_servers      => $glance_connection,
    verbose                 => $verbose,
    debug                   => $debug,
    ensure_package          => $ensure_package,
    log_facility            => $syslog_log_facility,
    use_syslog              => $use_syslog,
    use_stderr              => $use_stderr,
    database_idle_timeout   => $idle_timeout,
    report_interval         => $nova_report_interval,
    service_down_time       => $nova_service_down_time,
    notify_on_state_change  => $notify_on_state_change,
    notify_api_faults       => $nova_hash['notify_api_faults'],
    notification_driver     => $notification_driver,
    memcached_servers       => $memcached_addresses,
    cinder_catalog_info     => pick($nova_hash['cinder_catalog_info'], 'volumev2:cinderv2:internalURL'),
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

  $fping_path = $::osfamily ? {
    'Debian' => '/usr/bin/fping',
    'RedHat' => '/usr/sbin/fping',
    default => fail('Unsupported Operating System.'),
  }

  class {'nova::quota':
    quota_instances                       => pick($nova_hash['quota_instances'], 100),
    quota_cores                           => pick($nova_hash['quota_cores'], 100),
    quota_volumes                         => pick($nova_hash['quota_volumes'], 100),
    quota_gigabytes                       => pick($nova_hash['quota_gigabytes'], 1000),
    quota_floating_ips                    => pick($nova_hash['quota_floating_ips'], 100),
    quota_metadata_items                  => pick($nova_hash['quota_metadata_items'], 1024),
    quota_max_injected_files              => pick($nova_hash['quota_max_injected_files'], 50),
    quota_max_injected_file_content_bytes => pick($nova_hash['quota_max_injected_file_content_bytes'], 102400),
    quota_injected_file_path_length       => pick($nova_hash['quota_injected_file_path_length'], 4096),
    quota_security_groups                 => pick($nova_hash['quota_security_groups'], 10),
    quota_key_pairs                       => pick($nova_hash['quota_key_pairs'], 10),
    quota_driver                          => $nova_quota_driver
  }

  if ! $neutron {
    # Configure nova-network
    if $multi_host {
      nova_config { 'DEFAULT/multi_host': value => 'True' }
      $_enabled_apis = $enabled_apis
    } else {
      $_enabled_apis = "${enabled_apis},metadata"
    }
  }

  $default_limits = {
    'POST' => 10,
    'POST_SERVERS' => 50,
    'PUT' => 10,
    'GET' => 3,
    'DELETE' => 100,
  }

  $merged_limits = merge($default_limits, $nova_rate_limits)
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
  class { '::nova::api':
    enabled                              => $enabled,
    api_bind_address                     => $api_bind_address,
    admin_user                           => $nova_user,
    admin_password                       => $nova_user_password,
    admin_tenant_name                    => pick($nova_hash['admin_tenant_name'], $nova_user_tenant),
    identity_uri                         => $keystone_identity_uri,
    auth_uri                             => $keystone_auth_uri,
    auth_version                         => pick($nova_hash['auth_version'], false),
    enabled_apis                         => $_enabled_apis,
    ensure_package                       => $ensure_package,
    ratelimits                           => $nova_rate_limits_string,
    neutron_metadata_proxy_shared_secret => $neutron_metadata_proxy_shared_secret,
    require                              => Package['nova-common'],
    osapi_compute_workers                => $service_workers,
    metadata_workers                     => $service_workers,
    sync_db                              => $primary_controller,
    sync_db_api                          => $primary_controller,
    fping_path                           => $fping_path,
    api_paste_config                     => '/etc/nova/api-paste.ini';
  }

  # From legacy init.pp
  if !defined(Package[$pymemcache_package_name]) {
    package { $pymemcache_package_name:
      ensure => present,
    } ->
    Nova::Generic_service <| title == 'api' |>
  }

  if !($sql_connection) {
    Nova_config <<| tag == "${::deployment_id}::${::environment}" and title == 'connection' |>>
  }

  nova_config {
    'DEFAULT/allow_resize_to_same_host':  value => pick($nova_hash['allow_resize_to_same_host'], true);
    'keystone_authtoken/signing_dir':     value => '/tmp/keystone-signing-nova';
    'keystone_authtoken/signing_dirname': value => '/tmp/keystone-signing-nova';
  }

  nova_paste_api_ini {
    'filter:authtoken/signing_dir':       ensure => absent;
    'filter:authtoken/signing_dirname':   ensure => absent;
  }

  class {'::nova::conductor':
    enabled        => $enabled,
    ensure_package => $ensure_package,
    workers        => $service_workers,
    use_local      => $nova_hash['use_local'],
  }

  if $auto_assign_floating_ip {
    nova_config { 'DEFAULT/auto_assign_floating_ip': value => 'True' }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::cert',
  ]:
    enabled => $enabled,
    ensure_package => $ensure_package
  }

  class { '::nova::consoleauth':
    enabled        => $enabled,
    ensure_package => $ensure_package,
  }

  if $vnc_enabled {
    # TODO(aschultz): when the openstacklib & nova modules have been updated
    # with a version that supports os_package_type, remove this block
    # See LP#1530912
    if !$::os_package_type or $::os_package_type == 'debian' {
      Package<| title == 'nova-vncproxy' |> {
        name => 'nova-consoleproxy'
      }
    }
    class { 'nova::vncproxy':
      host           => $novnc_address,
      enabled        => $enabled,
      ensure_package => $ensure_package
    }
  }
}
