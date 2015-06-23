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
#   (optional) Deprecated. The rabbitmq puppet class to depend on,
#   which is dependent on the puppet-rabbitmq version.
#   Use the default for 1.x, use 'rabbitmq' for 3.x.
#   Use false if rabbitmq class should not be configured
#   here
#   Defaults to 'rabbitmq::server'
#
class cinder::rabbitmq(
  $userid         = 'guest',
  $password       = 'guest',
  $port           = '5672',
  $virtual_host   = '/',
  $enabled        = true,
  # DEPRECATED PARAMETER
  $rabbitmq_class = 'rabbitmq::server',
) {

  if ($enabled) {
    if $userid == 'guest' {
      $delete_guest_user = false
    } else {
      $delete_guest_user = true
      rabbitmq_user { $userid:
        admin    => true,
        password => $password,
        provider => 'rabbitmqctl',
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

  # NOTE(bogdando) do not cinder manage rabbitmq service
  # if rabbitmq_class is set to False
  if $rabbitmq_class {
    warning('The rabbitmq_class parameter is deprecated.')

    class { $rabbitmq_class:
      service_ensure    => $service_ensure,
      port              => $port,
      delete_guest_user => $delete_guest_user,
    }
    Class[$rabbitmq_class] -> Rabbitmq_user<| title == $userid |>
    Class[$rabbitmq_class] -> Rabbitmq_vhost<| title == $virtual_host |>
    # only configure cinder after the queue is up
    Class[$rabbitmq_class] -> Anchor<| title == 'cinder-start' |>
  }

  if ($enabled) {
    rabbitmq_vhost { $virtual_host:
      provider => 'rabbitmqctl',
    }
  }
}
