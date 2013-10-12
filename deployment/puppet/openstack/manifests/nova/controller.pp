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
#   rabbit_password    => 'changeme',
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
  $rabbit_password,
  # Nova Required
  $nova_user_password,
  $nova_db_password,
  primary_controller         = false,
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
  # AMQP
  $queue_provider             = 'rabbitmq',
  # Rabbit
  $rabbit_user               = 'nova',
  $rabbit_node_ip_address    = undef,
  $rabbit_port               = '5672',
  # Qpid
  $qpid_password             = 'qpid_pw',
  $qpid_user                 = 'nova',
  $qpid_nodes                = [$internal_address],
  $qpid_port                 = '5672',
  $qpid_node_ip_address      = undef,
  # Database
  $db_type                   = 'mysql',
  # Glance
  $glance_api_servers        = undef,
  # VNC
  $vnc_enabled               = true,
  # General
  $keystone_host             = '127.0.0.1',
  $verbose                   = 'False',
  $debug                     = 'False',
  $enabled                   = true,
  $exported_resources        = true,
  $rabbit_nodes              = [$internal_address],
  $rabbit_cluster            = false,
  $rabbit_ha_virtual_ip      = false,
  $nameservers               = undef,
  $ensure_package            = present,
  $enabled_apis              = 'ec2,osapi_compute',
  $api_bind_address          = '0.0.0.0',
  $use_syslog                = false,
  $syslog_log_facility       = 'LOCAL6',
  $syslog_log_facility_quantum = 'LOCAL4',
  $syslog_log_level = 'WARNING',
  $nova_rate_limits          = undef,
  $cinder                    = true
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}"
    }
  }

  if ($glance_api_servers == undef) {
    $real_glance_api_servers = "${public_address}:9292"
  } else {
    $real_glance_api_servers = $glance_api_servers
  }
  # Change the pool of rabbit server nodes for clients to single virtual IP for HA mode
    if $rabbit_ha_virtual_ip {
      if $quantum and $quantum_netnode_on_cnt {
        $rabbit_hosts = "${rabbit_ha_virtual_ip}"
      } else {
        $rabbit_hosts = "${rabbit_ha_virtual_ip}:5672"
      }
    } else {
      $rabbit_hosts = inline_template("<%= @rabbit_nodes.map {|x| x + ':5672'}.join ',' %>")
    }
  if ($exported_resources) {
    # export all of the things that will be needed by the clients
#    @@nova_config { 'DEFAULT/rabbit_host': value => $internal_address }
#    Nova_config <| title == 'rabbit_host' |>

    @@nova_config { 'DEFAULT/rabbit_hosts': value => $rabbit_hosts }
    Nova_config <| title == 'rabbit_hosts' |>

    @@nova_config { 'DEFAULT/sql_connection': value => $nova_db }
    Nova_config <| title == 'sql_connection' |>

    @@nova_config { 'DEFAULT/glance_api_servers': value => $real_glance_api_servers }
    Nova_config <| title == 'glance_api_servers' |>

    $sql_connection    = false
    $glance_connection = false
    $rabbit_connection = false
  } else {
    $sql_connection    = $nova_db
    $glance_connection = $real_glance_api_servers
    $rabbit_connection = $internal_address
  }

  # Install / configure queue provider
  case $queue_provider {
    'rabbitmq': {
      class { 'nova::rabbitmq':
        userid                 => $rabbit_user,
        password               => $rabbit_password,
        enabled                => $enabled,
        cluster                => $rabbit_cluster,
        cluster_nodes          => $rabbit_nodes, #Real node names to install RabbitMQ server onto
        rabbit_node_ip_address => $rabbit_node_ip_address,
        port                   => $rabbit_port,
      }
    }
    'qpid': {
      class { 'qpid::server':
        auth                   => 'yes',
        auth_realm             => 'QPID',
        log_to_file            => '/var/log/qpidd.log',
        cluster_mechanism      => 'DIGEST-MD5',
        qpid_username          => $qpid_user,
        qpid_password          => $qpid_password,
        qpid_nodes             => $qpid_nodes,
      }
    }
  }

  case $queue_provider {
    'rabbitmq': {
      if ($rabbit_nodes) {
        # Configure Nova
        class { 'nova':
          sql_connection       => $sql_connection,
          rabbit_userid        => $rabbit_user,
          rabbit_password      => $rabbit_password,
          image_service        => 'nova.image.glance.GlanceImageService',
          glance_api_servers   => $glance_connection,
          verbose              => $verbose,
          debug                => $debug,
          rabbit_nodes         => $rabbit_nodes,
          ensure_package       => $ensure_package,
          api_bind_address     => $api_bind_address,
          use_syslog           => $use_syslog,
          syslog_log_facility  => $syslog_log_facility,
          syslog_log_level     => $syslog_log_level,
          rabbit_ha_virtual_ip => $rabbit_ha_virtual_ip,
        }
      } else {
        class { 'nova':
          sql_connection     => $sql_connection,
          rabbit_userid      => $rabbit_user,
          rabbit_password    => $rabbit_password,
          image_service      => 'nova.image.glance.GlanceImageService',
          glance_api_servers => $glance_connection,
          verbose            => $verbose,
          debug              => $debug,
          rabbit_host        => $rabbit_connection,
          ensure_package     => $ensure_package,
          api_bind_address   => $api_bind_address,
          syslog_log_facility => $syslog_log_facility,
          syslog_log_level   => $syslog_log_level,
          use_syslog         => $use_syslog,
        }
      }
    }
    'qpid': {
      class { 'nova':
        sql_connection     => $sql_connection,
        queue_provider     => $queue_provider,
        qpid_userid        => $qpid_user,
        qpid_password      => $qpid_password,
        qpid_nodes         => $qpid_nodes,
        image_service      => 'nova.image.glance.GlanceImageService',
        glance_api_servers => $glance_connection,
        verbose            => $verbose,
        debug              => $debug,
        ensure_package     => $ensure_package,
        api_bind_address   => $api_bind_address,
        syslog_log_facility => $syslog_log_facility,
        syslog_log_level   => $syslog_log_level,
        use_syslog         => $use_syslog,
      }
    }
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
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
      ensure_package    => $ensure_package
    }
  } else {
    # Set up Quantum

    class { 'quantum::server':
      quantum_config     => $quantum_config,
      primary_controller => $primary_controller
    }
    if $quantum and !$quantum_network_node {
      class { '::quantum':
        quantum_config       => $quantum_config,
        verbose              => $verbose,
        debug                => $debug,
        use_syslog           => $use_syslog,
        syslog_log_facility  => $syslog_log_facility_quantum,
        syslog_log_level     => $syslog_log_level,
        server_ha_mode       => $ha_mode,
      }
    }
    class { 'nova::network::quantum':
      quantum_config => $quantum_config,
      quantum_connection_host => $service_endpoint
    }
  }

  # Configure nova-api
  class { 'nova::api':
    enabled           => $enabled,
    admin_password    => $nova_user_password,
    auth_host         => $keystone_host,
    enabled_apis      => $_enabled_apis,
    ensure_package    => $ensure_package,
    nova_rate_limits  => $nova_rate_limits,
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

  class {'nova::conductor':
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

  class { 'nova::consoleauth':
    enabled        => $enabled,
    ensure_package => $ensure_package,
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      host           => $public_address,
      enabled        => $enabled,
      ensure_package => $ensure_package
    }
  }

}

# vim: set ts=2 sw=2 et :