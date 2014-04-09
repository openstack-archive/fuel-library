# == Class: cinder::rabbitmq
#
# Installs and manages rabbitmq server for cinder
#
# == Parameters:
#
# [*userid*]
#   (optional) The username to use when connecting to Rabbit
#   Defaults to 'guest'
#
# [*password*]
#   (optional) The password to use when connecting to Rabbit
#   Defaults to 'guest'
#
# [*port*]
#   (optional) The port to use when connecting to Rabbit
#   Defaults to '5672'
#
# [*virtual_host*]
#   (optional) The virtual host to use when connecting to Rabbit
#   Defaults to '/'
#
# [*enabled*]
#   (optional) Whether to enable the Rabbit service
#   Defaults to false
#
# [*rabbitmq_class*]
#   (optional) The rabbitmq puppet class to depend on,
#   which is dependent on the puppet-rabbitmq version.
#   Use the default for 1.x, use 'rabbitmq' for 3.x
#   Defaults to 'rabbitmq::server'
#
class cinder::rabbitmq(
  $userid         = 'guest',
  $password       = 'guest',
  $port           = '5672',
  $virtual_host   = '/',
  $enabled        = true,
  $rabbitmq_class = 'rabbitmq::server',
) {

  # only configure cinder after the queue is up
  Class[$rabbitmq_class] -> Anchor<| title == 'cinder-start' |>

  if ($enabled) {
    if $userid == 'guest' {
      $delete_guest_user = false
    } else {
      $delete_guest_user = true
      rabbitmq_user { $userid:
        admin    => true,
        password => $password,
        provider => 'rabbitmqctl',
        require  => Class[$rabbitmq_class],
      }
      # I need to figure out the appropriate permissions
      rabbitmq_user_permissions { "${userid}@${virtual_host}":
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
      }->Anchor<| title == 'cinder-start' |>
    }
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  class { $rabbitmq_class:
    service_ensure    => $service_ensure,
    port              => $port,
    delete_guest_user => $delete_guest_user,
  }

  if ($enabled) {
    rabbitmq_vhost { $virtual_host:
      provider => 'rabbitmqctl',
      require  => Class[$rabbitmq_class],
    }
  }
}
