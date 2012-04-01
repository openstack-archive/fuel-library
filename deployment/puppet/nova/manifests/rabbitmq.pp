#
# class for installing rabbitmq server for nova
#
#
class nova::rabbitmq(
  $userid='guest',
  $password='guest',
  $port='5672',
  $virtual_host='/',
  $install_repo = false
) {

  # only configure nova after the queue is up
  Class['rabbitmq::service'] -> Anchor<| title == 'nova-start' |>

  # work around hostname bug, LP #653405
  # TODO - see if this is still required
  host { $hostname:
    ip => $ipaddress,
    host_aliases => $fqdn,
  }

  if $install_repo {
    # this is debian specific
    class { 'rabbitmq::repo::apt':
      pin    => 900,
      before => Class['rabbitmq::server']
    }
  }
  if $userid == 'guest' {
    $delete_guest_user = false
  } else {
    $delete_guest_user = true
    rabbitmq_user { $userid:
      admin     => true,
      password  => $password,
      provider => 'rabbitmqctl',
      require   => Class['rabbitmq::server'],
    }
    # I need to figure out the appropriate permissions
    rabbitmq_user_permissions { "${userid}@${virtual_host}":
      configure_permission => '.*',
      write_permission     => '.*',
      read_permission      => '.*',
      provider             => 'rabbitmqctl',
    }->Anchor<| title == 'nova-start' |>
  }
  class { 'rabbitmq::server':
    port              => $port,
    delete_guest_user => $delete_guest_user,
  }
  rabbitmq_vhost { $virtual_host:
    provider => 'rabbitmqctl',
    require => Class['rabbitmq::server'],
  }
}
