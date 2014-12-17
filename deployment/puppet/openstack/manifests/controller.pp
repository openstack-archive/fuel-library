# This can be used to build out the simplest openstack controller
#
# === Parameters
#
# [public_interface] Public interface used to route public traffic. Required.
# [public_address] Public address for public endpoints. Required.
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [mysql_root_password] Root password for mysql server.
# [admin_email] Admin email.
# [admin_password] Admin password.
# [keystone_db_password] Keystone database password.
# [keystone_admin_token] Admin token for keystone.
# [glance_db_password] Glance DB password.
# [glance_user_password] Glance service user password.
# [nova_db_password] Nova DB password.
# [nova_user_password] Nova service password.
# [amqp_password] AMQP password.
# [amqp_user] AMQP User.
# [network_manager] Nova network manager to use.
# [fixed_range] Range of ipv4 network for vms.
# [floating_range] Floating ip range to create.
# [create_networks] Rather network and floating ips should be created.
# [num_networks] Number of networks that fixed range should be split into.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [verbose] Rather to print more verbose (INFO+) output. Optional. Defaults to false.
# [debug] Rather to print even more verbose (DEBUG+) output. If true, would ignore verbose option.
#   Optional. Defaults to false.
# [export_resources] Rather to export resources.
# Horizon related config - assumes puppetlabs-horizon code
# [secret_key]          secret key to encode cookies, …
# [cache_server_ip]     local memcached instance ip
# [cache_server_port]   local memcached instance port
# [swift]               (bool) is swift installed
# [neutron]             (bool) is neutron installed
#   The next is an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   Each app is defined in two parts, the display name, and the URI
# [horizon_app_links]     array as in '[ ["Nagios","http://nagios_addr:port/path"],["Ganglia","http://ganglia_addr"] ]'
# [enabled] Whether services should be enabled. This parameter can be used to
#   implement services in active-passive modes for HA. Optional. Defaults to true.
# [use_syslog] Rather or not service should log to syslog. Optional. Defaults to false.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [max_retries] number of reconnects to Sqlalchemy db backend. Defaults -1.
# [max_pool_size] QueuePool setting for Sqlalchemy db backend. Defaults 10.
# [max_overflow] QueuePool setting for Sqlalchemy db backend. Defaults 30.
# [idle_timeout] QueuePool setting for Sqlalchemy db backend. Defaults 3600.
#
# === Examples
#
# class { 'openstack::controller':
#   public_address       => '192.168.0.3',
#   mysql_root_password  => 'changeme',
#   allowed_hosts        => ['127.0.0.%', '192.168.1.%'],
#   admin_email          => 'my_email@mw.com',
#   admin_password       => 'my_admin_password',
#   keystone_db_password => 'changeme',
#   keystone_admin_token => '12345',
#   glance_db_password   => 'changeme',
#   glance_user_password => 'changeme',
#   nova_db_password     => 'changeme',
#   nova_user_password   => 'changeme',
#   secret_key           => 'dummy_secret_key',
# }
#
class openstack::controller (
  # Required Network
  $public_address,
  $public_interface,
  $private_interface,
  # Required Database
  $mysql_root_password            = 'sql_pass',
  $custom_mysql_setup_class       = undef,
  $admin_email                    = 'some_user@some_fake_email_address.foo',
  $admin_user                     = 'admin',
  $admin_password                 = 'ChangeMe',
  $keystone_db_password           = 'keystone_pass',
  $keystone_admin_token           = 'keystone_admin_token',
  # Required Glance
  $glance_db_password             = 'glance_pass',
  $glance_user_password           = 'glance_pass',
  # Required Nova
  $nova_db_password               = 'nova_pass',
  $nova_user_password             = 'nova_pass',
  # Required Ceilometer
  $ceilometer                     = false,
  $ceilometer_db_password         = 'ceilometer_pass',
  $ceilometer_user_password       = 'ceilometer_pass',
  $ceilometer_db_user             = 'ceilometer',
  $ceilometer_db_dbname           = 'ceilometer',
  $ceilometer_metering_secret     = 'ceilometer',
  $ceilometer_db_type             = 'mongodb',
  $ceilometer_db_host             = '127.0.0.1',
  $swift_rados_backend            = false,
  # Required Horizon
  $secret_key                     = 'dummy_secret_key',
  # not sure if this works correctly
  $internal_address,
  $admin_address,
  # RPC
  $queue_provider                 = 'rabbitmq',
  $amqp_hosts                     = '127.0.0.1',
  $amqp_user                      = 'nova',
  $amqp_password                  = 'rabbit_pw',
  $rabbit_ha_queues               = false,
  $rabbitmq_bind_ip_address       = 'UNSET',
  $rabbitmq_bind_port             = '5672',
  $rabbitmq_cluster_nodes         = [],
  $rabbit_cluster                 = false,
  # network configuration
  # this assumes that it is a flat network manager
  $network_manager                = 'nova.network.manager.FlatDHCPManager',
  $fixed_range                    = '10.0.0.0/24',
  $floating_range                 = false,
  $create_networks                = true,
  $num_networks                   = 1,
  $network_size                   = 255,
  $multi_host                     = false,
  $auto_assign_floating_ip        = false,
  $network_config                 = {},
  # Database
  $db_host                        = '127.0.0.1',
  $db_type                        = 'mysql',
  $mysql_account_security         = true,
  $mysql_bind_address             = '0.0.0.0',
  $allowed_hosts                  = [ '%', $::hostname ],
  # Keystone
  $keystone_db_user               = 'keystone',
  $keystone_db_dbname             = 'keystone',
  $keystone_admin_tenant          = 'admin',
  # Glance
  $glance_db_user                 = 'glance',
  $glance_db_dbname               = 'glance',
  $glance_api_servers             = undef,
  $glance_image_cache_max_size    = '10737418240',
  $known_stores                   = false,
  $glance_vcenter_host            = undef,
  $glance_vcenter_user            = undef,
  $glance_vcenter_password        = undef,
  $glance_vcenter_datacenter      = undef,
  $glance_vcenter_datastore       = undef,
  $glance_vcenter_image_dir       = undef,
  # Nova
  $nova_db_user                   = 'nova',
  $nova_db_dbname                 = 'nova',
  $purge_nova_config              = false,
  $nova_report_interval           = '10',
  $nova_service_down_time         = '60',

  # Horizon
  $cache_server_ip                = ['127.0.0.1'],
  $cache_server_port              = '11211',
  $swift                          = false,
  $cinder                         = true,
  $horizon_app_links              = undef,
  # General
  $verbose                        = false,
  $debug                          = false,
  $export_resources               = true,
  # if the cinder management components should be installed
  $cinder_user_password           = 'cinder_user_pass',
  $cinder_db_password             = 'cinder_db_pass',
  $cinder_db_user                 = 'cinder',
  $cinder_db_dbname               = 'cinder',
  $cinder_iscsi_bind_addr         = false,
  $cinder_volume_group            = 'cinder-volumes',

  #[Nova|Neutron] Network
  $network_provider               = 'nova',
  $neutron_db_user                = 'neutron',
  $neutron_db_password            = 'neutron_db_pass',
  $neutron_db_dbname              = 'neutron',
  $neutron_user_password          = 'asdf123',
  $neutron_metadata_proxy_secret  = '12345',
  $neutron_ha_agents              = false,
  $base_mac                       = 'fa:16:3e:00:00:00',

  $segment_range                  = '1:4094',
  $tenant_network_type            = 'gre',
  $enabled                        = true,
  $api_bind_address               = '0.0.0.0',
  $service_endpoint               = '127.0.0.1',
  $galera_cluster_name            = 'openstack',
  $primary_controller             = false,
  $galera_node_address            = '127.0.0.1',
  $glance_backend                 = 'file',
  $galera_nodes                   = ['127.0.0.1'],
  $novnc_address                  = '127.0.0.1',
  $mysql_skip_name_resolve        = false,
  $manage_volumes                 = false,
  $nv_physical_volume             = undef,
  $use_syslog                     = false,
  $syslog_log_facility_ceilometer = 'LOG_LOCAL0',
  $syslog_log_facility_glance     = 'LOG_LOCAL2',
  $syslog_log_facility_cinder     = 'LOG_LOCAL3',
  $syslog_log_facility_neutron    = 'LOG_LOCAL4',
  $syslog_log_facility_nova       = 'LOG_LOCAL6',
  $syslog_log_facility_keystone   = 'LOG_LOCAL7',
  $horizon_use_ssl                = false,
  $nova_rate_limits               = undef,
  $cinder_rate_limits             = undef,
  $ha_mode                        = false,
  $nameservers                    = undef,
  $memcached_bind_address         = undef,
  #
  $max_retries                    = '-1',
  $max_pool_size                  = '50',
  $max_overflow                   = '30',
  $idle_timeout                   = '3600',
) {

  # Ensure things are run in order
  Class['openstack::db::mysql'] -> Class['openstack::keystone']
  if ($ceilometer) {
    Class['openstack::db::mysql'] -> Class['openstack::ceilometer']
  }
  Class['openstack::db::mysql'] -> Class['openstack::glance']
  Class['openstack::db::mysql'] -> Class['openstack::nova::controller']
  Class['openstack::db::mysql'] -> Cinder_config <||>

  Class["${queue_provider}::server"] -> Nova_config <||>
  Class["${queue_provider}::server"] -> Cinder_config <||>
  Class["${queue_provider}::server"] -> Neutron_config <||>

  ####### DATABASE SETUP ######
  # set up mysql server
  if ($db_type == 'mysql') {
    if ($enabled) {
      Class['glance::db::mysql'] -> Class['glance::registry']
    }
    class { 'openstack::db::mysql':
      mysql_root_password     => $mysql_root_password,
      mysql_bind_address      => $mysql_bind_address,
      mysql_account_security  => $mysql_account_security,
      keystone_db_user        => $keystone_db_user,
      keystone_db_password    => $keystone_db_password,
      keystone_db_dbname      => $keystone_db_dbname,
      glance_db_user          => $glance_db_user,
      glance_db_password      => $glance_db_password,
      glance_db_dbname        => $glance_db_dbname,
      nova_db_user            => $nova_db_user,
      nova_db_password        => $nova_db_password,
      nova_db_dbname          => $nova_db_dbname,
      ceilometer              => $ceilometer,
      ceilometer_db_user      => $ceilometer_db_user,
      ceilometer_db_password  => $ceilometer_db_password,
      ceilometer_db_dbname    => $ceilometer_db_dbname,
      cinder                  => $cinder,
      cinder_db_user          => $cinder_db_user,
      cinder_db_password      => $cinder_db_password,
      cinder_db_dbname        => $cinder_db_dbname,
      neutron                 => $network_provider ? {'nova' => false, 'neutron' => true},
      neutron_db_user         => $neutron_db_user,
      neutron_db_password     => $neutron_db_password,
      neutron_db_dbname       => $neutron_db_dbname,
      allowed_hosts           => $allowed_hosts,
      enabled                 => $enabled,
      galera_cluster_name     => $galera_cluster_name,
      primary_controller      => $primary_controller,
      galera_node_address     => $galera_node_address ,
      #db_host                 => $internal_address,
      galera_nodes            => $galera_nodes,
      custom_setup_class      => $custom_mysql_setup_class,
      mysql_skip_name_resolve => $mysql_skip_name_resolve,
      use_syslog              => $use_syslog,
    }
  }
  ####### KEYSTONE ###########
  class { 'openstack::keystone':
    verbose                   => $verbose,
    debug                     => $debug,
    db_type                   => $db_type,
    db_host                   => $db_host,
    db_password               => $keystone_db_password,
    db_name                   => $keystone_db_dbname,
    db_user                   => $keystone_db_user,
    admin_token               => $keystone_admin_token,
    admin_tenant              => $keystone_admin_tenant,
    admin_email               => $admin_email,
    admin_user                => $admin_user,
    admin_password            => $admin_password,
    public_address            => $public_address,
    internal_address          => $internal_address,
    admin_address             => $admin_address,
    glance_user_password      => $glance_user_password,
    nova_user_password        => $nova_user_password,
    cinder                    => $cinder,
    cinder_user_password      => $cinder_user_password,
    neutron                   => $network_provider ? {'nova' => false, 'neutron' => true},
    neutron_user_password     => $neutron_user_password,
    ceilometer                => $ceilometer,
    ceilometer_user_password  => $ceilometer_user_password,
    bind_host                 => $api_bind_address,
    enabled                   => $enabled,
    package_ensure            => $::openstack_keystone_version,
    use_syslog                => $use_syslog,
    syslog_log_facility       => $syslog_log_facility_keystone,
    memcache_servers          => $cache_server_ip,
    memcache_server_port      => $cache_server_port,
    max_retries               => $max_retries,
    max_pool_size             => $max_pool_size,
    max_overflow              => $max_overflow,
    rabbit_password           => $amqp_password,
    rabbit_userid             => $amqp_user,
    rabbit_hosts              => split($amqp_hosts, ','),
    rabbit_virtual_host       => $rabbit_virtual_host,
    idle_timeout              => $idle_timeout,
  }


  ######## BEGIN GLANCE ##########
  class { 'openstack::glance':
    verbose                      => $verbose,
    debug                        => $debug,
    db_type                      => $db_type,
    db_host                      => $db_host,
    glance_db_user               => $glance_db_user,
    glance_db_dbname             => $glance_db_dbname,
    glance_db_password           => $glance_db_password,
    glance_user_password         => $glance_user_password,
    glance_vcenter_host          => $glance_vcenter_host,
    glance_vcenter_user          => $glance_vcenter_user,
    glance_vcenter_password      => $glance_vcenter_password,
    glance_vcenter_datacenter    => $glance_vcenter_datacenter,
    glance_vcenter_datastore     => $glance_vcenter_datastore,
    glance_vcenter_image_dir     => $glance_vcenter_image_dir,
    auth_uri                     => "http://${service_endpoint}:5000/",
    keystone_host                => $service_endpoint,
    bind_host                    => $api_bind_address,
    enabled                      => $enabled,
    glance_backend               => $glance_backend,
    registry_host                => $service_endpoint,
    use_syslog                   => $use_syslog,
    syslog_log_facility          => $syslog_log_facility_glance,
    glance_image_cache_max_size  => $glance_image_cache_max_size,
    max_retries                  => $max_retries,
    max_pool_size                => $max_pool_size,
    max_overflow                 => $max_overflow,
    idle_timeout                 => $idle_timeout,
    rabbit_password              => $amqp_password,
    rabbit_userid                => $amqp_user,
    rabbit_hosts                 => $amqp_hosts,
    rabbit_virtual_host          => $rabbit_virtual_host,
    rabbit_use_ssl               => $rabbit_use_ssl,
    rabbit_notification_exchange => $rabbit_notification_exchange,
    rabbit_notification_topic    => $rabbit_notification_topic,
    known_stores                 => $known_stores,
  }

  ######## BEGIN NOVA ###########
  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }
  if ($cinder) {
    $enabled_apis = 'ec2,osapi_compute'
  }
  else {
    $enabled_apis = 'ec2,osapi_compute,osapi_volume'
  }

  if $::fuel_settings['nova_quota'] {
    $nova_quota_driver = "nova.quota.DbQuotaDriver"
  } else {
    $nova_quota_driver = "nova.quota.NoopQuotaDriver"
  }

  class { 'openstack::nova::controller':
    # Database
    db_host                     => $db_host,
    # Network
    nameservers                 => $nameservers,
    network_manager             => $network_manager,
    floating_range              => $floating_range,
    fixed_range                 => $fixed_range,
    public_address              => $public_address,
    public_interface            => $public_interface,
    admin_address               => $admin_address,
    internal_address            => $internal_address,
    private_interface           => $private_interface,
    auto_assign_floating_ip     => $auto_assign_floating_ip,
    create_networks             => $create_networks,
    num_networks                => $num_networks,
    network_size                => $network_size,
    multi_host                  => $multi_host,
    network_config              => $network_config,
    keystone_host               => $service_endpoint,
    service_endpoint            => $service_endpoint,
    # Neutron
    neutron                     => $network_provider ? {'nova' => false, 'neutron' => true},
    segment_range               => $segment_range,
    tenant_network_type         => $tenant_network_type,
    # Nova
    nova_user_password          => $nova_user_password,
    nova_db_password            => $nova_db_password,
    nova_db_user                => $nova_db_user,
    nova_db_dbname              => $nova_db_dbname,
    nova_quota_driver           => $nova_quota_driver,
    # RPC
    queue_provider              => $queue_provider,
    amqp_hosts                  => $amqp_hosts,
    amqp_user                   => $amqp_user,
    amqp_password               => $amqp_password,
    rabbit_ha_queues            => $rabbit_ha_queues,
    rabbitmq_bind_ip_address    => $rabbitmq_bind_ip_address,
    rabbitmq_bind_port          => $rabbitmq_bind_port,
    rabbitmq_cluster_nodes      => $rabbitmq_cluster_nodes,
    rabbit_cluster              => $rabbit_cluster,
    cache_server_ip             => $cache_server_ip,
    cache_server_port           => $cache_server_port,
    # Glance
    glance_api_servers          => $glance_api_servers,
    # General
    verbose                     => $verbose,
    primary_controller          => $primary_controller,
    debug                       => $debug,
    enabled                     => $enabled,
    exported_resources          => $export_resources,
    enabled_apis                => $enabled_apis,
    api_bind_address            => $api_bind_address,
    ensure_package              => $::openstack_version['nova'],
    use_syslog                  => $use_syslog,
    syslog_log_facility         => $syslog_log_facility_nova,
    syslog_log_facility_neutron => $syslog_log_facility_neutron,
    nova_rate_limits            => $nova_rate_limits,
    nova_report_interval        => $nova_report_interval,
    nova_service_down_time      => $nova_service_down_time,
    cinder                      => $cinder,
    # SQLAlchemy backend
    max_retries                 => $max_retries,
    max_pool_size               => $max_pool_size,
    max_overflow                => $max_overflow,
    idle_timeout                => $idle_timeout,
    novnc_address               => $novnc_address,
    ha_mode                     => $ha_mode,
    neutron_metadata_proxy_shared_secret => $network_provider ? {'nova'=>undef, 'neutron'=>$neutron_metadata_proxy_secret },
  }

  ######### Cinder Controller Services ########
  if $cinder {
    if !defined(Class['openstack::cinder']) {
      class {'openstack::cinder':
        sql_connection       => "mysql://${cinder_db_user}:${cinder_db_password}@${db_host}/${cinder_db_dbname}?charset=utf8&read_timeout=60",
        queue_provider       => $queue_provider,
        amqp_hosts           => $amqp_hosts,
        amqp_user            => $amqp_user,
        amqp_password        => $amqp_password,
        rabbit_ha_queues     => $rabbit_ha_queues,
        volume_group         => $cinder_volume_group,
        physical_volume      => $nv_physical_volume,
        manage_volumes       => $manage_volumes,
        enabled              => true,
        glance_api_servers   => "${service_endpoint}:9292",
        auth_host            => $service_endpoint,
        bind_host            => $api_bind_address,
        iscsi_bind_host      => $cinder_iscsi_bind_addr,
        cinder_user_password => $cinder_user_password,
        use_syslog           => $use_syslog,
        verbose              => $verbose,
        debug                => $debug,
        syslog_log_facility  => $syslog_log_facility_cinder,
        cinder_rate_limits   => $cinder_rate_limits,
        max_retries          => $max_retries,
        max_pool_size        => $max_pool_size,
        max_overflow         => $max_overflow,
        idle_timeout         => $idle_timeout,
        ceilometer           => $ceilometer,
      } # end class
    } else { # defined
      if $manage_volumes {
      # Set up nova-volume
        class { 'nova::volume':
          ensure_package => $::openstack_version['nova'],
          enabled        => true,
        }
        class { 'nova::volume::iscsi':
          iscsi_ip_address => $api_bind_address,
          physical_volume  => $nv_physical_volume,
        }
      } #end manage_volumes
    } #end else
  } #end cinder

  if !defined(Class['memcached']){
    class { 'memcached':
      listen_ip => $memcached_bind_address,
    }
  }

  ######## Ceilometer ########

  if ($ceilometer) {
    class { 'openstack::ceilometer':
      verbose              => $verbose,
      debug                => $debug,
      use_syslog           => $use_syslog,
      syslog_log_facility  => $syslog_log_facility_ceilometer,
      db_type              => $ceilometer_db_type,
      db_host              => $ceilometer_db_host,
      db_user              => $ceilometer_db_user,
      db_password          => $ceilometer_db_password,
      db_dbname            => $ceilometer_db_dbname,
      swift_rados_backend  => $swift_rados_backend,
      metering_secret      => $ceilometer_metering_secret,
      amqp_hosts           => $amqp_hosts,
      amqp_user            => $amqp_user,
      amqp_password        => $amqp_password,
      rabbit_ha_queues     => $rabbit_ha_queues,
      keystone_host        => $internal_address,
      keystone_password    => $ceilometer_user_password,
      host                 => $api_bind_address,
      ha_mode              => $ha_mode,
      primary_controller   => $primary_controller,
      on_controller        => true,
      use_neutron          => $network_provider ? {'nova' => false, 'neutron' => true},
      swift                => $swift,
    }
  }

  ######## Horizon ########
  class { 'openstack::horizon':
    secret_key        => $secret_key,
    cache_server_ip   => $cache_server_ip,
    package_ensure    => $::openstack_version['horizon'],
    bind_address      => $api_bind_address,
    cache_server_port => $cache_server_port,
    swift             => $swift,
    neutron           => $network_provider ? {'nova' => false, 'neutron' => true},
    horizon_app_links => $horizon_app_links,
    keystone_host     => $service_endpoint,
    use_ssl           => $horizon_use_ssl,
    verbose           => $verbose,
    debug             => $debug,
    use_syslog        => $use_syslog,
    nova_quota        => $::fuel_settings['nova_quota'],
  }
  class { 'openstack::auth_file':
    admin_user           => $admin_user,
    admin_password       => $admin_password,
    admin_tenant         => $keystone_admin_tenant,
    controller_node      => $internal_address,
  }

  ####### Disable upstart startup on install #######
  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'glance-api':
      package_name => 'glance-api',
    }
    tweaks::ubuntu_service_override { 'glance-registry':
      package_name => 'glance-registry',
    }
    tweaks::ubuntu_service_override { ['murano_api', 'murano_engine']:
      package_name => 'murano',
    }
    tweaks::ubuntu_service_override { 'heat-api-cloudwatch':
      package_name => 'heat-api-cloudwatch',
    }
    tweaks::ubuntu_service_override { 'heat-api-cfn':
      package_name => 'heat-api-cfn',
    }
    tweaks::ubuntu_service_override { 'heat-api':
      package_name => 'heat-api',
    }
    tweaks::ubuntu_service_override { 'sahara-api':
      package_name => 'sahara',
    }
    tweaks::ubuntu_service_override { 'keystone':
      package_name => 'keystone',
    }
    # Ceph rbd backend configures its override on its own
    if !$::fuel_settings['storage']['volumes_ceph'] {
      tweaks::ubuntu_service_override { 'cinder-volume':
        package_name => 'cinder-volume',
      }
    }
    tweaks::ubuntu_service_override { 'cinder-api':
      package_name => 'cinder-api',
    }
    tweaks::ubuntu_service_override { 'cinder-backup':
      package_name => 'cinder-backup',
    }
    tweaks::ubuntu_service_override { 'cinder-scheduler':
      package_name => 'cinder-scheduler',
    }
    tweaks::ubuntu_service_override { 'nova-cert':
      package_name => 'nova-cert',
    }
    tweaks::ubuntu_service_override { 'nova-conductor':
      package_name => 'nova-conductor',
    }
    tweaks::ubuntu_service_override { 'nova-consoleproxy':
      package_name => 'nova-consoleproxy',
    }
    tweaks::ubuntu_service_override { 'nova-api':
      package_name => 'nova-api',
    }
    tweaks::ubuntu_service_override { 'nova-objectstore':
      package_name => 'nova-objectstore',
    }
    tweaks::ubuntu_service_override { 'nova-scheduler':
      package_name => 'nova-scheduler',
    }
    tweaks::ubuntu_service_override { 'nova-consoleauth':
      package_name => 'nova-consoleauth',
    }
    tweaks::ubuntu_service_override { 'nova-vncproxy':
      package_name => 'nova-vncproxy',
    }
    tweaks::ubuntu_service_override { 'nova-spiceproxy':
      package_name => 'nova-spiceproxy',
    }
    tweaks::ubuntu_service_override { 'nova-spicehtml5proxy':
      package_name => 'nova-spicehtml5proxy',
    }
    tweaks::ubuntu_service_override { 'nova-cells':
      package_name => 'nova-cells',
    }
  }


  ######## [Nova|Neutron] Network ########

  if $network_manager !~ /VlanManager$/ and $network_config {
    $config_overrides = delete($network_config, 'vlan_start')
  } else {
    $config_overrides = $network_config
  }

  if $network_provider == 'neutron' {
    $neutron_db_uri = "mysql://${neutron_db_user}:${neutron_db_password}@${db_host}/${neutron_db_dbname}?&read_timeout=60"
    $neutron_server = true

    # FIXME(xarses) Nearly everything between here and the class
    # should be moved into osnaily or nailgun but will stay here
    # in the interum.
    $neutron_settings = $::fuel_settings['quantum_settings']
    $nets = $neutron_settings['predefined_networks']

    if $primary_controller {

      Service<| title == 'neutron-server' |> ->
        Openstack::Network::Create_network <||>

      Service<| title == 'neutron-server' |> ->
        Openstack::Network::Create_router <||>

      openstack::network::create_network{'net04':
        netdata => $nets['net04']
      } ->
      openstack::network::create_network{'net04_ext':
        netdata => $nets['net04_ext']
      } ->
      openstack::network::create_router{'router04':
        internal_network => 'net04',
        external_network => 'net04_ext',
        tenant_name      => $keystone_admin_tenant
      }
    }
    $pnets = $neutron_settings['L2']['phys_nets']
    if $pnets['physnet1'] {
      $physnet1 = "physnet1:${pnets['physnet1']['bridge']}"
      notify{ $physnet1:}
    }
    if $pnets['physnet2'] {
      $physnet2 = "physnet2:${pnets['physnet2']['bridge']}"
      notify{ $physnet2:}
      if $pnets['physnet2']['vlan_range'] {
        $vlan_range = ["physnet2:${pnets['physnet2']['vlan_range']}"]
        $fallback = split($pnets['physnet2']['vlan_range'], ':')
        Openstack::Network::Create_network {
          tenant_name         => $keystone_admin_tenant,
          fallback_segment_id => $fallback[1]
        }
        notify{ $vlan_range:}
      }
    } else {
      $vlan_range = []
    }

    if $physnet1 and $physnet2 {
      $bridge_mappings = [$physnet1, $physnet2]
    } elsif $physnet1 {
      $bridge_mappings = [$physnet1]
    } elsif $physnet2 {
      $bridge_mappings = [$physnet2]
    } else {
      $bridge_mappings = []
    }

    if $neutron_settings['L2']['tunnel_id_ranges'] {
      $enable_tunneling = true
      $tunnel_id_ranges = [$neutron_settings['L2']['tunnel_id_ranges']]
      $alt_fallback = split($neutron_settings['L2']['tunnel_id_ranges'], ':')
      Openstack::Network::Create_network {
        tenant_name         => $keystone_admin_tenant,
        fallback_segment_id => $alt_fallback[0]
      }

    } else {
      $enable_tunneling = false
      $tunnel_id_ranges = []
    }
    notify{ $tunnel_id_ranges:}

    if $neutron_settings['L2']['mechanism_drivers'] {
        $mechanism_drivers = split($neutron_settings['L2']['mechanism_drivers'], ',')
    } else {
        $mechanism_drivers = ['openvswitch']
    }

    if $neutron_settings['L2']['provider'] == 'ovs' {
      $core_plugin      = 'openvswitch'
      $service_plugins  = ['router', 'firewall', 'metering']
      $agent            = 'ovs'
    } elsif $neutron_settings['L2']['provider'] == 'nsx' {
      $core_plugin = 'vmware'
    } else {
      $core_plugin      = 'neutron.plugins.ml2.plugin.Ml2Plugin'
      $service_plugins  = ['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin','neutron.services.metering.metering_plugin.MeteringPlugin']
      $agent            = 'ml2-ovs'
    }

  } else {
    $neutron_server = false
    $neutron_db_uri = undef
  }

  Class['openstack::keystone'] ->
  class { 'openstack::network':
    network_provider    => $network_provider,
    agents              => [$agent, 'metadata', 'dhcp', 'l3'],
    ha_agents           => $neutron_ha_agents,
    verbose             => $verbose,
    debug               => $debug,
    use_syslog          => $use_syslog,
    syslog_log_facility => $syslog_log_facility_neutron,

    neutron_server      => $neutron_server,
    neutron_db_uri      => $neutron_db_uri,
    public_address      => $public_address,
    internal_address    => $internal_address, # Could be this node or, internal_vip
    admin_address       => $admin_address,
    nova_neutron        => true,
    base_mac            => $base_mac,
    core_plugin         => $core_plugin,
    service_plugins     => $service_plugins,

    #ovs
    mechanism_drivers   => $mechanism_drivers,
    local_ip            => $::internal_address, # $::internal_adress is this node
    bridge_mappings     => $bridge_mappings,
    network_vlan_ranges => $vlan_range,
    enable_tunneling    => $enable_tunneling,
    tunnel_id_ranges    => $tunnel_id_ranges,

    #Queue settings
    queue_provider  => $queue_provider,
    amqp_hosts      => [$amqp_hosts],
    amqp_user       => $amqp_user,
    amqp_password   => $amqp_password,

    # keystone
    admin_password  => $neutron_user_password,
    auth_host       => $internal_address,
    auth_url        => "http://${service_endpoint}:35357/v2.0",
    neutron_url     => "http://${service_endpoint}:9696",

    #metadata
    shared_secret   => $neutron_metadata_proxy_secret,
    metadata_ip     => $service_endpoint,

    #nova settings
    private_interface   => $private_interface,
    public_interface    => $public_interface,
    fixed_range         => $fixed_range,
    floating_range      => $floating_range,
    network_manager     => $network_manager,
    network_config      => $config_overrides,
    create_networks     => $create_networks,
    num_networks        => $num_networks,
    network_size        => $network_size,
    nameservers         => $nameservers,
    enable_nova_net     => false,  # just setup networks, but don't start nova-network service on controllers
    nova_admin_password => $nova_user_password,
    nova_url            => "http://${service_endpoint}:8774/v2",
  }
}

