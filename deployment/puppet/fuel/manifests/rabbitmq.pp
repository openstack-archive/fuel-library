class fuel::rabbitmq (
  $rabbitmq_gid       = $::fuel::params::rabbitmq_gid,
  $rabbitmq_uid       = $::fuel::params::rabbitmq_uid,

  $astute_user        = $::fuel::params::rabbitmq_astute_user,
  $astute_password    = $::fuel::params::rabbitmq_astute_password,

  $mco_user           = $::fuel::params::mco_user,
  $mco_password       = $::fuel::params::mco_password,
  $mco_vhost          = $::fuel::params::mco_vhost,

  $bind_ip            = $::fuel::params::mco_host,
  $management_bind_ip = $::fuel::params::rabbitmq_management_bind_ip,
  $management_port    = $::fuel::params::rabbitmq_management_port,
  $stompport          = $::fuel::params::mco_port,
  $env_config         = {},
  $stomp              = false,
  ) inherits fuel::params {

  include stdlib
  anchor { 'rabbitmq-begin' :}
  anchor { 'rabbitmq-end' :}

  file { '/etc/default/rabbitmq-server':
    ensure  => absent,
    require => Package['rabbitmq-server'],
    before  => Service['rabbitmq-server'],
  }

  group { "rabbitmq" :
    provider => "groupadd",
    ensure   => "present",
    gid      => $rabbitmq_gid,
  }

  user { "rabbitmq":
    ensure     => present,
    managehome => true,
    uid        => $rabbitmq_uid,
    gid        => $rabbitmq_gid,
    shell      => '/bin/bash',
    home       => '/var/lib/rabbitmq',
    comment    => 'RabbitMQ messaging server',
    require    => Group["rabbitmq"],
  }

  file { "/var/log/rabbitmq":
    ensure  => directory,
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0755',
    require => User['rabbitmq'],
    before  => Service["rabbitmq-server"],
  }

  rabbitmq_user { $astute_user:
    admin     => true,
    password  => $astute_password,
    provider  => 'rabbitmqctl',
    require   => Class['::rabbitmq'],
  }

  rabbitmq_vhost { "/":
    require => Class['::rabbitmq'],
  }

  rabbitmq_user_permissions { "${astute_user}@/":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => [Class['::rabbitmq'], Rabbitmq_vhost['/']]
  }

  file { "/etc/rabbitmq/enabled_plugins":
    content => '[amqp_client,rabbitmq_stomp,rabbitmq_management].',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package["rabbitmq-server"],
    notify  => Service["rabbitmq-server"],
  }

  if $stomp {
    $actual_mco_vhost = "/"
  } else {
    rabbitmq_vhost { $mco_vhost:
      require => Class['::rabbitmq'],
    }
    $actual_mco_vhost = $mco_vhost
  }

  rabbitmq_user { $mco_user:
    admin     => true,
    password  => $mco_password,
    provider  => 'rabbitmqctl',
    require   => Class['::rabbitmq'],
  }

  rabbitmq_user_permissions { "${mco_user}@${actual_mco_vhost}":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['::rabbitmq'],
  }

  exec { 'create-mcollective-directed-exchange':

    command   => "curl -L -i -u ${mco_user}:${mco_password} -H   \"content-type:application/json\" -XPUT \
      -d'{\"type\":\"direct\",\"durable\":true}'\
      http://${management_bind_ip}:${management_port}/api/exchanges/${actual_mco_vhost}/mcollective_directed",
    logoutput => true,
    require   => [
                 Service['rabbitmq-server'],
                 Rabbitmq_user_permissions["${mco_user}@${actual_mco_vhost}"],
                 ],
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    tries     => 10,
    try_sleep => 3,
  }

  exec { 'create-mcollective-broadcast-exchange':
    command   => "curl -L -i -u ${mco_user}:${mco_password} -H \"content-type:application/json\" -XPUT \
      -d'{\"type\":\"topic\",\"durable\":true}' \
      http://${management_bind_ip}:${management_port}/api/exchanges/${actual_mco_vhost}/mcollective_broadcast",
    logoutput => true,
    require   => [Service['rabbitmq-server'],
  Rabbitmq_user_permissions["${mco_user}@${actual_mco_vhost}"]],
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    tries     => 10,
    try_sleep => 3,
  }

  $rabbitmq_management_variables = {
    'listener' => "[
      {port, ${management_port}},
      {ip, \"${management_bind_ip}\"}
    ]"
  }

  # NOTE(bogdando) requires rabbitmq module >=4.0
  class { '::rabbitmq':
    repos_ensure            => false,
    package_provider        => 'yum',
    package_source          => undef,
    environment_variables   => $env_config,
    service_ensure          => 'running',
    delete_guest_user       => true,
    config_cluster          => false,
    cluster_nodes           => [],
    config_stomp            => true,
    stomp_port              => $stompport,
    ssl                     => false,
    node_ip_address         => $bind_ip,
    tcp_keepalive           => true,
    config_kernel_variables => {
     'inet_dist_listen_min'         => '41055',
     'inet_dist_listen_max'         => '41055',
     'inet_default_connect_options' => '[{nodelay,true}]',
    },
    config_variables => {
      'log_levels'                  => '[{connection,debug,info,error}]',
      'default_vhost'               => '<<"">>',
      'default_permissions'         => '[<<".*">>, <<".*">>, <<".*">>]',
    },

    config_management_variables     => $rabbitmq_management_variables,
    require => User["rabbitmq"],
  }

  # NOTE(bogdando) retries for the rabbitmqadmin curl command, unmerged MODULES-1650
  Staging::File <| title == 'rabbitmqadmin' |> {
    tries       => 30,
    try_sleep   => 6,
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

  Anchor['rabbitmq-begin'] ->
  Class['::rabbitmq'] ->
  Anchor['rabbitmq-end']
}
