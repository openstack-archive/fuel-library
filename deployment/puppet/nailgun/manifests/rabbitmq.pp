class nailgun::rabbitmq (
  $naily_password = 'naily',
  $naily_user     = 'naily',
) {

  rabbitmq_user { $naily_user:
    admin     => true,
    password  => $naily_password,
    provider  => 'rabbitmqctl',
    require   => Class['rabbitmq::server'],
  }

  rabbitmq_user_permissions { "${naily_user}@/":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['rabbitmq::server'],
  }

}
