class nailgun::rabbitmq (
  $production      = 'prod',
  $astute_password = 'astute',
  $astute_user     = 'astute',
  $mco_user        = 'mcollective',
  $mco_password    = 'marionette',
  $mco_vhost       = 'mcollective',
  $stomp           = false,
) {

  $management_port = "55672"
  $stompport = "61613"

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
    require   => Class['rabbitmq::server'],
  }

  rabbitmq_user_permissions { "${astute_user}@/":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['rabbitmq::server'],
  }

  #TODO(mattymo): Refactor mcollective::rabbitmq to not include iptables rule
  # and call that class here instead.
  if $production =~ /docker/ {
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
      require   => Class['rabbitmq::server'],
    }

    rabbitmq_user_permissions { "${mco_user}@${actual_vhost}":
      configure_permission => '.*',
      write_permission     => '.*',
      read_permission      => '.*',
      provider             => 'rabbitmqctl',
      require              => Class['rabbitmq::server'],
    }

    exec { 'create-mcollective-directed-exchange':

      command   => "curl -i -u ${mco_user}:${mco_password} -H   \"content-type:application/json\" -XPUT \
        -d'{\"type\":\"direct\",\"durable\":true}'\
        http://localhost:${management_port}/api/exchanges/${aactual_vhost}/mcollective_directed",
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
      command   => "curl -i -u ${mco_user}:${mco_password} -H \"content-type:application/json\" -XPUT \
        -d'{\"type\":\"topic\",\"durable\":true}'\
        http://localhost:${management_port}/api/exchanges/${actual_vhost}/mcollective_broadcast",
      logoutput => true,
      require   => [Service['rabbitmq-server'],
    Rabbitmq_user_permissions["${mco_user}@${actual_vhost}"]],
      path      => '/bin:/usr/bin:/sbin:/usr/sbin',
      tries     => 10,
      try_sleep => 3,
    }
  }
  class { 'rabbitmq::server':
    service_ensure     => running,
    delete_guest_user  => true,
    config_cluster     => false,
    cluster_disk_nodes => [],
    config_stomp       => true,
    stomp_port         => $stompport,
    node_ip_address    => 'UNSET',
  }
}
