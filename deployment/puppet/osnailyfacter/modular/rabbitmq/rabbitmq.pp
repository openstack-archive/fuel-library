notice('MODULAR: rabbitmq.pp')

$queue_provider = hiera('queue_provider', 'rabbitmq')

if $queue_provider == 'rabbitmq' {
  $enabled         = true
  $erlang_cookie   = hiera('erlang_cookie', 'EOKOWXQREETZSHFNTPEY')
  $version         = hiera('rabbit_version', '3.3.5')
  $debug           = hiera('debug', false)
  $deployment_mode = hiera('deployment_mode', 'ha_compact')
  $amqp_port       = hiera('amqp_port', '5673')
  $rabbit_hash     = hiera('rabbit_hash',
    {
      'user'     => false,
      'password' => false,
    }
  )

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
    $rabbit_levels = '[connection,debug,info,error]'
  } else {
    $rabbit_levels = '[connection,info,error]'
  }

  $cluster_partition_handling = hiera('rabbit_cluster_partition_handling', 'autoheal')
  $rabbitmq_bind_ip_address   = hiera('rabbitmq_bind_ip_address','UNSET')
  # NOTE(bogdando) not a hash. Keep an indentation as is
  $rabbit_tcp_listen_options  = hiera('rabbit_tcp_listen_options',
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
    }
  )
  $config_variables = hiera('rabbit_config_variables',
    {
      'log_levels'                 => $rabbit_levels,
      'default_vhost'              => "<<\"/\">>",
      'default_permissions'        => '[<<".*">>, <<".*">>, <<".*">>]',
      'tcp_listen_options'         => $rabbit_tcp_listen_options,
      'cluster_partition_handling' => $cluster_partition_handling,
    }
  )
  if $deployment_mode == 'ha_compact' {
    $rabbit_pid_file                   = '/var/run/rabbitmq/p_pid'
    } else {
    $rabbit_pid_file                   = '/var/run/rabbitmq/pid'
  }
  $environment_variables = hiera('rabbit_environment_variables',
    {
      'RABBIT_SERVER_ERL_ARGS'       => '"+K true +A30 +P 1048576"',
      'RABBITMQ_PID_FILE'            => $rabbit_pid_file,
    }
  )

  class { '::rabbitmq':
    repos_ensure               => false,
    package_provider           => $package_provider,
    package_source             => undef,
    service_ensure             => 'running',
    service_manage             => true,
    port                       => $amqp_port,
    delete_guest_user          => true,
    default_user               => $rabbit_hash['user'],
    default_pass               => $rabbit_hash['password'],
    # NOTE(bogdando) set to true and uncomment the lines below, if puppet should create a cluster
    # We don't want it as far as OCF script creates the cluster
    config_cluster             => false,
    #erlang_cookie              => $erlang_cookie,
    #wipe_db_on_cookie_change   => true,
    #cluster_nodes              => $rabbitmq_cluster_nodes,
    #cluster_node_type          => 'disc',
    #cluster_partition_handling => $cluster_partition_handling,
    version                    => $version,
    node_ip_address            => $rabbitmq_bind_ip_address,
    config_kernel_variables    => $config_kernel_variables,
    config_variables           => $config_variables,
    environment_variables      => $environment_variables,
  }

  class { 'nova::rabbitmq':
    enabled                    => $enabled,
    # Do not install rabbitmq from nova classes
    rabbitmq_class             => false,
    userid                     => $rabbit_hash['user'],
    password                   => $rabbit_hash['password'],
    require                    => Class['::rabbitmq'],
  }

  if $enabled {
    class { 'pacemaker_wrappers::rabbitmq':
      command_timeout         => $command_timeout,
      debug                   => $debug,
      #TODO(bogdando) make erlang cookie as a hiera(astute) value.
      erlang_cookie           => 'EOKOWXQREETZSHFNTPEY',
      before                  => Class['nova::rabbitmq'],
    }
  }
}
