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
#   public_address     => '192.168.1.1',
#   db_host            => '127.0.0.1',
#   amqp_password    => 'changeme',
#   nova_user_password => 'changeme',
#   nova_db_password   => 'changeme',
# }
#

class openstack::nova::controller (
  # Network Required
  $public_address,
  $public_interface,
  $private_interface,
  # Database Required
  $db_host,
  # Rabbit Required
  $amqp_password,
  # Nova Required
  $nova_user_password,
  $nova_db_password,
  $primary_controller         = false,
  # Network
  $fixed_range               = '10.0.0.0/24',
  $floating_range            = false,
  $internal_address,
  $admin_address,
  $service_endpoint          = '127.0.0.1',
  $auto_assign_floating_ip   = false,
  $create_networks           = true,
  $num_networks              = 1,
  $network_size              = 255,
  $multi_host                = false,
  $network_config            = {},
  $network_manager           = 'nova.network.manager.FlatDHCPManager',
  $nova_quota_driver         = 'nova.quota.NoopQuotaDriver',
  # Quantum
  $quantum                   = false,
  $quantum_config            = {},
  $quantum_network_node      = false,
  $quantum_netnode_on_cnt    = false,
  $segment_range             = '1:4094',
  $tenant_network_type       = 'gre',
  # Nova
  $nova_db_user              = 'nova',
  $nova_db_dbname            = 'nova',
  # RPC
  $queue_provider            = 'rabbitmq',
  $amqp_hosts                = ['127.0.0.1'],
  $amqp_user                 = 'nova',
  $amqp_password             = 'rabbit_pw',
  $rabbit_ha_queues          = false,
  $rabbitmq_bind_ip_address  = 'UNSET',
  $rabbitmq_bind_port        = '5672',
  $rabbitmq_cluster_nodes    = [],
  $rabbit_cluster            = false,
  # Database
  $db_type                   = 'mysql',
  # Glance
  $glance_api_servers        = undef,
  # VNC
  $vnc_enabled               = true,
  # General
  $keystone_host             = '127.0.0.1',
  $verbose                   = false,
  $debug                     = false,
  $enabled                   = true,
  $exported_resources        = true,
  $nameservers               = undef,
  $ensure_package            = present,
  $enabled_apis              = 'ec2,osapi_compute',
  $api_bind_address          = '0.0.0.0',
  $use_syslog                = false,
  $syslog_log_facility       = 'LOG_LOCAL6',
  $syslog_log_facility_neutron = 'LOG_LOCAL4',
  $syslog_log_level = 'WARNING',
  $nova_rate_limits          = undef,
  $nova_report_interval      = '10',
  $nova_service_down_time    = '60',
  $cinder                    = true,
  # SQLAlchemy backend
  $idle_timeout              = '3600',
  $max_pool_size             = '10',
  $max_overflow              = '30',
  $max_retries               = '-1',
  $novnc_address             = '127.0.0.1'
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}?read_timeout=60"
    }
  }

  if ($glance_api_servers == undef) {
    $real_glance_api_servers = "${public_address}:9292"
  } else {
    $real_glance_api_servers = $glance_api_servers
  }
  $sql_connection    = $nova_db
  $glance_connection = $real_glance_api_servers

  # Install / configure queue provider
  case $queue_provider {
    'rabbitmq': {
      class { 'nova::rabbitmq':
        enabled                => $enabled,
        userid                 => $amqp_user,
        password               => $amqp_password,
        rabbit_node_ip_address => $rabbitmq_bind_ip_address,
        port                   => $rabbitmq_bind_port,
        cluster_nodes          => $rabbitmq_cluster_nodes,
        cluster                => $rabbit_cluster,
      }
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

  class { 'nova':
    sql_connection      => $sql_connection,
    amqp_hosts          => $amqp_hosts,
    amqp_user           => $amqp_user,
    amqp_password       => $amqp_password,
    rabbit_ha_queues    => $rabbit_ha_queues,
    image_service       => 'nova.image.glance.GlanceImageService',
    glance_api_servers  => $glance_connection,
    verbose             => $verbose,
    debug               => $debug,
    ensure_package      => $ensure_package,
    api_bind_address    => $api_bind_address,
    syslog_log_facility => $syslog_log_facility,
    syslog_log_level    => $syslog_log_level,
    use_syslog          => $use_syslog,
    max_retries         => $max_retries,
    max_pool_size       => $max_pool_size,
    max_overflow        => $max_overflow,
    idle_timeout        => $idle_timeout,
    report_interval     => $nova_report_interval,
    service_down_time   => $nova_service_down_time,
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
    quota_max_injected_file_path_bytes    => 4096
  }

  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }

  if ! $quantum {
    # Configure nova-network
    if $multi_host {
      nova_config { 'DEFAULT/multi_host': value => 'True' }

      $enable_network_service = false
      $_enabled_apis = $enabled_apis
    } else {
      if $enabled {
        $enable_network_service = true
      } else {
        $enable_network_service = false
      }

      $_enabled_apis = "${enabled_apis},metadata"
    }

    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => $floating_range,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => $really_create_networks,
      num_networks      => $num_networks,
      network_size      => $network_size,
      nameservers       => $nameservers,
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
      ensure_package    => $ensure_package
    }
  } else {
    # Set up Quantum
    #todo: move to ::openstack:controller and ::openstack:neutron_router
    #todo: from HERE to <<<
    class { '::neutron::server':
      neutron_config     => $quantum_config,
      primary_controller => $primary_controller
    }
    if $quantum and !$quantum_network_node {
      class { '::neutron':
        neutron_config       => $quantum_config,
        verbose              => $verbose,
        debug                => $debug,
        use_syslog           => $use_syslog,
        syslog_log_facility  => $syslog_log_facility_neutron,
        syslog_log_level     => $syslog_log_level,
        server_ha_mode       => $ha_mode,
      }
    }
    #todo: <<<
    class { '::nova::network::neutron':
      #neutron_config => $quantum_config,
      #neutron_connection_host => $service_endpoint
      neutron_admin_password    => $quantum_config['keystone']['admin_password'],
      neutron_admin_tenant_name => $quantum_config['keystone']['admin_tenant_name'],
      neutron_region_name       => $quantum_config['keystone']['auth_region'],
      neutron_admin_username    => $quantum_config['keystone']['admin_user'],
      neutron_admin_auth_url    => $quantum_config['keystone']['auth_url'],
      neutron_url               => $quantum_config['server']['api_url'],
    }
  }

  # Configure nova-api
  class { '::nova::api':
    enabled           => $enabled,
    admin_password    => $nova_user_password,
    auth_host         => $keystone_host,
    enabled_apis      => $_enabled_apis,
    ensure_package    => $ensure_package,
    nova_rate_limits  => $nova_rate_limits,
    nova_quota_driver => $nova_quota_driver,
    cinder            => $cinder
  }

  # Do not enable it!!!!!
  # metadata service provides by nova api
  # while enabled_apis=ec2,osapi_compute,metadata
  # and by quantum-metadata-agent on network node as proxy
  #
  # enable nova-metadata-api service
  #class { 'nova::metadata_api':
  #  enabled => $enabled,
  #  ensure_package => $ensure_package,
  #}

  class {'::nova::conductor':
    enabled => $enabled,
    ensure_package => $ensure_package,
  }

  if $auto_assign_floating_ip {
    nova_config { 'DEFAULT/auto_assign_floating_ip': value => 'True' }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::objectstore',
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
    class { 'nova::vncproxy':
      host           => $novnc_address,
      enabled        => $enabled,
      ensure_package => $ensure_package
    }
  }

}
