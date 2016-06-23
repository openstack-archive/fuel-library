class osnailyfacter::rabbitmq::rabbitmq {

  notice('MODULAR: rabbitmq/rabbitmq.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  $workers_max = hiera('workers_max', 50)

  prepare_network_config($network_scheme)

  $queue_provider = hiera('queue_provider', 'rabbit')

  if $queue_provider == 'rabbit' {
    $erlang_cookie   = hiera('erlang_cookie', 'EOKOWXQREETZSHFNTPEY')
    $version         = hiera('rabbit_version', '3.3.5')
    $amqp_port       = hiera('amqp_port', '5673')
    $rabbit_hash     = hiera_hash('rabbit',
      {
        'user'     => false,
        'password' => false,
      }
    )
    $rabbit_ocf_default = {
        'start_timeout'       => '180',
        'stop_timeout'        => '120',
        'mon_timeout'         => '180',
        'promote_timeout'     => '120',
        'demote_timeout'      => '120',
        'notify_timeout'      => '180',
        'slave_mon_interval'  => '30',
        'master_mon_interval' => '27',
        'mon_interval'        => '35',
    }
    $rabbit_ocf = merge($rabbit_ocf_default, hiera_hash('rabbit_ocf', {}))
    $debug           = pick($rabbit_hash['debug'], hiera('debug', false))
    $enabled         = pick($rabbit_hash['enabled'], true)
    $use_pacemaker   = pick($rabbit_hash['pacemaker'], true)
    $file_limit     = pick($rabbit_hash['file_limit'], '100000')
    $pid_file        = pick($rabbit_hash['pid_file'], '/var/run/rabbitmq/p_pid')

    case $::osfamily {
      'RedHat': {
        $command_timeout  = '-s KILL'
        $package_provider = 'yum'
      }
      'Debian': {
        $command_timeout  = '--signal=KILL'
        $package_provider = 'apt'
      }
      default: {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem},\
    module ${module_name} only support osfamily RedHat and Debian")
      }
    }

    $rabbit_levels = sprintf('[{connection, %s}]',
      $debug ? { true => 'debug', default => 'info' }
    )

    $cluster_partition_handling   = hiera('rabbit_cluster_partition_handling', 'ignore')
    $mnesia_table_loading_timeout = hiera('mnesia_table_loading_timeout', '10000')
    $rabbitmq_bind_ip_address     = pick(get_network_role_property('mgmt/messaging', 'ipaddr'), 'UNSET')
    $management_bind_ip_address   = hiera('management_bind_ip_address', '127.0.0.1')
    $management_port              = hiera('rabbit_management_port', '15672')
    $enable_rpc_ha                = hiera('enable_rpc_ha', 'false')
    $enable_notifications_ha      = hiera('enable_notifications_ha', 'true')
    $fqdn_prefix                  = hiera('node_name_prefix_for_messaging', 'messaging-')

    # NOTE(mattymo) UNSET is a puppet ref, but would break real configs
    if $rabbitmq_bind_ip_address == 'UNSET' {
      $epmd_bind_ip_address = '0.0.0.0'
    } else {
      $epmd_bind_ip_address = $rabbitmq_bind_ip_address
    }

    $configuration = hiera_hash('configuration', {})

    $config_vars = pick($configuration['rabbitmq'], {})

    $config_kernel_variables = pick(
      $config_vars['kernel'],
      hiera_hash('rabbit_config_kernel_variables', {})
    )
    $config_kernel_variables_default =       {
        'inet_dist_listen_min'         => '41055',
        'inet_dist_listen_max'         => '41055',
        'inet_default_connect_options' => '[{nodelay,true}]',
        'net_ticktime'                 => '10',
    }
    $config_kernel_variables_merged = merge ($config_kernel_variables_default, $config_kernel_variables)

    $config_variables_default = {
      'log_levels'                   => $rabbit_levels,
      'default_vhost'                => "<<\"/\">>",
      'default_permissions'          => '[<<".*">>, <<".*">>, <<".*">>]',
      'cluster_partition_handling'   => $cluster_partition_handling,
      'mnesia_table_loading_timeout' => $mnesia_table_loading_timeout,
      'collect_statistics_interval'  => '30000',
      'disk_free_limit'              => '5000000', # Corosync checks for disk space, reduce rabbitmq check to 5M see LP#1493520 comment #15
      # TODO(mpolenchuk) Get optimal value for number of
      # Erlang processes that will accept connections
      'num_tcp_acceptors'            => 10,
    }

    $config_variables = pick($config_vars['application'], hiera_hash('rabbit_config_variables', {}))
    $config_variables_merged = merge($config_variables_default, $config_variables)

    $config_management_variables = pick($config_vars['management'], hiera_hash('rabbit_config_management_variables', {}))

    $config_management_variables_default ={
        'rates_mode' => 'none',
      }

    $config_management_variables_merged = merge($config_management_variables_default, $config_management_variables)
    # NOTE(bogdando) to get the limit for threads, the max amount of worker processess will be doubled
    $thread_pool_calc = min($workers_max*2,max(12*$physicalprocessorcount,30))

    $environment_variables_init = hiera('rabbit_environment_variables',
      {
        'SERVER_ERL_ARGS'     => "\"+K true +A${thread_pool_calc} +P 1048576\"",
        'ERL_EPMD_ADDRESS'    => $epmd_bind_ip_address,
        'PID_FILE'            => $pid_file,
      }
    )
    $environment_variables = merge($environment_variables_init, {
      'NODENAME'        => "rabbit@${fqdn_prefix}${::hostname}",
      'NODE_IP_ADDRESS' => $rabbitmq_bind_ip_address,
    })

    $rabbitmq_admin_enabled = true

    if ($enabled) {
      class { '::rabbitmq':
        admin_enable                => $rabbitmq_admin_enabled,
        management_port             => $management_port,
        repos_ensure                => false,
        package_provider            => $package_provider,
        package_source              => undef,
        service_ensure              => 'running',
        service_manage              => true,
        port                        => $amqp_port,
        delete_guest_user           => true,
        default_user                => $rabbit_hash['user'],
        default_pass                => $rabbit_hash['password'],
        # NOTE(bogdando) set to true and uncomment the lines below, if puppet should create a cluster
        # We don't want it as far as OCF script creates the cluster
        config_cluster              => false,
        #erlang_cookie              => $erlang_cookie,
        #wipe_db_on_cookie_change   => true,
        #cluster_nodes              => $rabbitmq_cluster_nodes,
        #cluster_node_type          => 'disc',
        #cluster_partition_handling => $cluster_partition_handling,
        version                     => $version,
        node_ip_address             => $management_bind_ip_address,
        config_kernel_variables     => $config_kernel_variables_merged,
        config_management_variables => $config_management_variables_merged,
        config_variables            => $config_variables_merged,
        environment_variables       => $environment_variables,
        file_limit                  => $file_limit,
        tcp_keepalive               => true,
      }

      # NOTE(bogdando) retries for the rabbitmqadmin curl command, unmerged MODULES-1650
      Staging::File <| title == 'rabbitmqadmin' |> {
          tries       => 30,
          try_sleep   => 6,
      }

      if $rabbitmq_admin_enabled {
        ensure_resource('service_status', ['rabbitmq'], { 'ensure' => 'online', check_cmd => 'rabbitmqctl cluster_status'})
  
        Service_status['rabbitmq'] -> Staging::File['rabbitmqadmin']
      }

      # TODO(bogdando) contribute this to puppetlabs-rabbitmq
      # Start epmd as rabbitmq so it doesn't run as root when installing plugins
      exec { 'epmd_daemon':
        command => 'epmd -daemon',
        path    => '/bin:/sbin:/usr/bin:/usr/sbin',
        user    => 'rabbitmq',
        group   => 'rabbitmq',
        unless  => 'pgrep epmd',
      }
      # Make sure the various providers have their requirements in place.
      Class['::rabbitmq::install'] -> Exec['epmd_daemon']
        -> Rabbitmq_plugin<| |> -> Rabbitmq_exchange<| |>

      if ($use_pacemaker) {
        # Install rabbit-fence daemon
        class { '::cluster::rabbitmq_fence':
          enabled => $enabled,
          require => Class['::rabbitmq']
        }
      }

      class { '::nova::rabbitmq':
        enabled  => $enabled,
        userid   => $rabbit_hash['user'],
        password => $rabbit_hash['password'],
        require  => Class['::rabbitmq'],
      }

      if ($use_pacemaker) {
        class { '::cluster::rabbitmq_ocf':
          command_timeout         => $command_timeout,
          debug                   => $debug,
          erlang_cookie           => $erlang_cookie,
          admin_user              => $rabbit_hash['user'],
          admin_pass              => $rabbit_hash['password'],
          host_ip                 => $management_bind_ip_address,
          before                  => Class['::nova::rabbitmq'],
          enable_rpc_ha           => $enable_rpc_ha,
          enable_notifications_ha => $enable_notifications_ha,
          fqdn_prefix             => $fqdn_prefix,
          pid_file                => $pid_file,
          # NOTE(bogdando) The fuel-libraryX package installs the custom
          # policy file by the given path. So not a hardcode.
          policy_file             => '/usr/sbin/set_rabbitmq_policy',
          start_timeout           => $rabbit_ocf['start_timeout'],
          stop_timeout            => $rabbit_ocf['stop_timeout'],
          mon_timeout             => $rabbit_ocf['mon_timeout'],
          promote_timeout         => $rabbit_ocf['promote_timeout'],
          demote_timeout          => $rabbit_ocf['demote_timeout'],
          notify_timeout          => $rabbit_ocf['notify_timeout'],
          slave_mon_interval      => $rabbit_ocf['slave_mon_interval'],
          master_mon_interval     => $rabbit_ocf['master_mon_interval'],
          mon_interval            => $rabbit_ocf['mon_interval'],
          require                 => Class['::rabbitmq::install'],
        }
      }

      include ::rabbitmq::params
      tweaks::ubuntu_service_override { 'rabbitmq-server':
        package_name => $rabbitmq::params::package_name,
        service_name => $rabbitmq::params::service_name,
      }
    }

  }

}
