class nailgun::rabbitmq (
  $production      = 'prod',
  $astute_password = 'astute',
  $astute_user     = 'astute',
  $mco_user        = 'mcollective',
  $mco_password    = 'marionette',
  $mco_vhost       = 'mcollective',
  $stomp           = false,
  $management_port = '15672',
  $stompport       = '61613',
  $rabbitmq_host   = 'localhost',
  $env_config      = {},
) {

  include stdlib
  anchor { 'nailgun::rabbitmq start' :}
  anchor { 'nailgun::rabbitmq end' :}

  if $production =~ /docker/ {
    #Known issue: ulimit is disabled inside docker containers
    file { '/etc/default/rabbitmq-server':
      ensure  => absent,
      require => Package['rabbitmq-server'],
      before  => Service['rabbitmq-server'],
    }
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
    content => template("mcollective/enabled_plugins.erb"),
    owner   => root,
    group   => root,
    mode    => 0644,
    require => Package["rabbitmq-server"],
    notify  => Service["rabbitmq-server"],
  }

  if $stomp {
    $actual_vhost = "/"
  } else {
    rabbitmq_vhost { $mco_vhost: }
    $actual_vhost = $mco_vhost
  }

  rabbitmq_user { $mco_user:
    admin     => true,
    password  => $mco_password,
    provider  => 'rabbitmqctl',
    require   => Class['::rabbitmq'],
  }

  rabbitmq_user_permissions { "${mco_user}@${actual_vhost}":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['::rabbitmq'],
  }

  exec { 'create-mcollective-directed-exchange':

    command   => "curl -L -i -u ${mco_user}:${mco_password} -H   \"content-type:application/json\" -XPUT \
      -d'{\"type\":\"direct\",\"durable\":true}'\
      http://localhost:${management_port}/api/exchanges/${actual_vhost}/mcollective_directed",
    logoutput => true,
    require   => [
                 Service['rabbitmq-server'],
                 Rabbitmq_user_permissions["${mco_user}@${actual_vhost}"],
                 ],
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    tries     => 10,
    try_sleep => 3,
  }

  exec { 'create-mcollective-broadcast-exchange':
    command   => "curl -L -i -u ${mco_user}:${mco_password} -H \"content-type:application/json\" -XPUT \
      -d'{\"type\":\"topic\",\"durable\":true}'\
      http://localhost:${management_port}/api/exchanges/${actual_vhost}/mcollective_broadcast",
    logoutput => true,
    require   => [Service['rabbitmq-server'],
  Rabbitmq_user_permissions["${mco_user}@${actual_vhost}"]],
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    tries     => 10,
    try_sleep => 3,
  }

  # NOTE(bogdando) indentation is important
  $rabbit_tcp_listen_options =
    '[
      binary,
      {packet, raw},
      {reuseaddr, true},
      {backlog, 128},
      {nodelay, true},
      {exit_on_close, false},
      {keepalive, true}
    ]'

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
    node_ip_address         => 'UNSET',
    config_kernel_variables => {
     'inet_dist_listen_min'         => '41055',
     'inet_dist_listen_max'         => '41055',
     'inet_default_connect_options' => '[{nodelay,true}]',
    },
    config_variables => {
      'log_levels'                  => '[connection,debug,info,error]',
      'default_vhost'               => '<<"">>',
      'default_permissions'         => '[<<".*">>, <<".*">>, <<".*">>]',
      'tcp_listen_options'          => $rabbit_tcp_listen_options,
    },
  }

  Anchor['nailgun::rabbitmq start'] ->
  Class['::rabbitmq'] ->
  Anchor['nailgun::rabbitmq end']

}
