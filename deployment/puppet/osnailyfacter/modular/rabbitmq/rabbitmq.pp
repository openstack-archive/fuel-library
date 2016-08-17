notice('MODULAR: rabbitmq.pp')

$network_scheme = hiera_hash('network_scheme', {})
$workers_max = hiera('workers_max', 50)

prepare_network_config($network_scheme)

$queue_provider = hiera('queue_provider', 'rabbitmq')

if $queue_provider == 'rabbitmq' {
  $erlang_cookie   = hiera('erlang_cookie', 'EOKOWXQREETZSHFNTPEY')
  $version         = hiera('rabbit_version', '3.3.5')
  $amqp_port       = hiera('amqp_port', '5673')
  $rabbit_hash     = hiera_hash('rabbit_hash',
    {
      'user'     => false,
      'password' => false,
    }
  )
  $debug           = pick($rabbit_hash['debug'], hiera('debug', false))
  $enabled         = pick($rabbit_hash['enabled'], true)
  $use_pacemaker   = pick($rabbit_hash['pacemaker'], true)
  $pid_file        = pick($rabbit_hash['pid_file'], '/var/run/rabbitmq/p_pid')

  case $::osfamily {
    'RedHat': {
      $command_timeout  = "'-s KILL'"
      $package_provider = 'yum'
    }
    'Debian': {
      $command_timeout  = "'--signal=KILL'"
      $package_provider = 'apt'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem},\
  module ${module_name} only support osfamily RedHat and Debian")
    }
  }

  if ($debug) {
    # FIXME(aschultz): debug wasn't introduced until v3.5.0, when we upgrade
    # we should change info to debug. Also don't forget to fix tests!
    $rabbit_levels = '[{connection,info}]'
  } else {
    $rabbit_levels = '[{connection,info}]'
  }

  $cluster_partition_handling   = hiera('rabbit_cluster_partition_handling', 'autoheal')
  $mnesia_table_loading_timeout = hiera('mnesia_table_loading_timeout', '10000')
  $rabbitmq_bind_ip_address     = pick(get_network_role_property('mgmt/messaging', 'ipaddr'), 'UNSET')
  $management_bind_ip_address   = hiera('management_bind_ip_address', '127.0.0.1')
  $enable_rpc_ha                = hiera('enable_rpc_ha', 'true')
  $enable_notifications_ha      = hiera('enable_notifications_ha', 'true')
  $fqdn_prefix                  = hiera('node_name_prefix_for_messaging', 'messaging-')

  # NOTE(mattymo) UNSET is a puppet ref, but would break real configs
  if $rabbitmq_bind_ip_address == 'UNSET' {
    $epmd_bind_ip_address = '0.0.0.0'
  } else {
    $epmd_bind_ip_address = $rabbitmq_bind_ip_address
  }

  # NOTE(bogdando) not a hash. Keep an indentation as is
  $rabbit_tcp_listen_options    = hiera('rabbit_tcp_listen_options',
    '[
      binary,
      {packet, raw},
      {reuseaddr, true},
      {backlog, 128},
      {nodelay, true},
      {exit_on_close, false},
      {keepalive, true}
    ]'
  )
  $config_kernel_variables = hiera('rabbit_config_kernel_variables',
    {
      'inet_dist_listen_min'         => '41055',
      'inet_dist_listen_max'         => '41055',
      'inet_default_connect_options' => '[{nodelay,true}]',
      'net_ticktime'                 => '60',
    }
  )
  $config_variables = hiera('rabbit_config_variables',
    {
      'log_levels'                   => $rabbit_levels,
      'default_vhost'                => "<<\"/\">>",
      'default_permissions'          => '[<<".*">>, <<".*">>, <<".*">>]',
      'tcp_listen_options'           => $rabbit_tcp_listen_options,
      'cluster_partition_handling'   => $cluster_partition_handling,
      'mnesia_table_loading_timeout' => $mnesia_table_loading_timeout,
      'collect_statistics_interval'  => '30000',
      'disk_free_limit'              => '5000000', # Corosync checks for disk space, reduce rabbitmq check to 5M see LP#1493520 comment #15
    }
  )
  $config_rabbitmq_management_variables = hiera('rabbit_config_management_variables',
    {
      'rates_mode' => 'none',
      'listener'   => "[{port, 15672}, {ip,\"${management_bind_ip_address}\"}]",
    }
  )
  # NOTE(bogdando) to get the limit for threads, the max amount of worker processess will be doubled
  $thread_pool_calc = min($workers_max*2,max(12*$physicalprocessorcount,30))

  $environment_variables_init = hiera('rabbit_environment_variables',
    {
      'SERVER_ERL_ARGS'     => "\"+K true +A${thread_pool_calc} +P 1048576\"",
      'ERL_EPMD_ADDRESS'    => $epmd_bind_ip_address,
      'PID_FILE'            => $pid_file,
    }
  )
  $environment_variables = merge($environment_variables_init,{'NODENAME' => "rabbit@${fqdn_prefix}${hostname}"})

  if ($enabled) {
    class { '::rabbitmq':
      admin_enable                         => true,
      repos_ensure                         => false,
      package_provider                     => $package_provider,
      package_source                       => undef,
      service_ensure                       => 'running',
      service_manage                       => true,
      port                                 => $amqp_port,
      delete_guest_user                    => true,
      default_user                         => $rabbit_hash['user'],
      default_pass                         => $rabbit_hash['password'],
      # NOTE(bogdando) set to true and uncomment the lines below, if puppet should create a cluster
      # We don't want it as far as OCF script creates the cluster
      config_cluster                       => false,
      #erlang_cookie                       => $erlang_cookie,
      #wipe_db_on_cookie_change            => true,
      #cluster_nodes                       => $rabbitmq_cluster_nodes,
      #cluster_node_type                   => 'disc',
      #cluster_partition_handling          => $cluster_partition_handling,
      version                              => $version,
      node_ip_address                      => $rabbitmq_bind_ip_address,
      config_kernel_variables              => $config_kernel_variables,
      config_rabbitmq_management_variables => $config_rabbitmq_management_variables,
      config_variables                     => $config_variables,
      environment_variables                => $environment_variables,
    }

    if ($use_pacemaker) {
      # Install rabbit-fence daemon
      class { 'cluster::rabbitmq_fence':
        enabled => $enabled,
        require => Class['::rabbitmq']
      }
    }

    class { 'nova::rabbitmq':
      enabled        => $enabled,
      userid         => $rabbit_hash['user'],
      password       => $rabbit_hash['password'],
      require        => Class['::rabbitmq'],
    }

    if ($use_pacemaker) {
      class { 'pacemaker_wrappers::rabbitmq':
        command_timeout         => $command_timeout,
        debug                   => $debug,
        erlang_cookie           => $erlang_cookie,
        admin_user              => $rabbit_hash['user'],
        admin_pass              => $rabbit_hash['password'],
        host_ip                 => $rabbitmq_bind_ip_address,
        before                  => Class['nova::rabbitmq'],
        enable_rpc_ha           => $enable_rpc_ha,
        enable_notifications_ha => $enable_notifications_ha,
        fqdn_prefix             => $fqdn_prefix,
        pid_file                => $pid_file,
      }
    }

    include rabbitmq::params
    tweaks::ubuntu_service_override { 'rabbitmq-server':
      package_name => $rabbitmq::params::package_name,
      service_name => $rabbitmq::params::service_name,
    }
  }

}
