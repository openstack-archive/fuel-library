class murano::rabbitmq(
  $rabbit_user            = 'murano',
  $rabbit_password        = 'murano',
  $rabbit_virtual_host    = '/',
) {

  rabbitmq_user { $rabbit_user:
    admin     => false,
    password  => $rabbit_password,
    provider  => 'rabbitmqctl',
    require   => Class['rabbitmq::server'],
  }

  rabbitmq_user_permissions { "${rabbit_user}@${rabbit_virtual_host}":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
  }

}
