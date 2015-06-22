# == Class: nova::rabbitmq
#
# Installs and manages rabbitmq server for nova
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
# [*cluster_disk_nodes*]
#   (optional) Enables/disables RabbitMQ clustering.  Specify an array of Rabbit Broker
#   IP addresses to configure clustering.
#   Defaults to false
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
class nova::rabbitmq(
  $userid             ='guest',
  $password           ='guest',
  $port               ='5672',
  $virtual_host       ='/',
  $cluster_disk_nodes = false,
  $enabled            = true,
  # DEPRECATED PARAMETER
  $rabbitmq_class     = 'rabbitmq::server'
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
      }->Anchor<| title == 'nova-start' |>
    }
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  # NOTE(bogdando) do not nova manage rabbitmq service
  # if rabbitmq_class is set to False
  if $rabbitmq_class {
    warning('The rabbitmq_class parameter is deprecated.')

    if $cluster_disk_nodes {
      class { $rabbitmq_class:
        service_ensure           => $service_ensure,
        port                     => $port,
        delete_guest_user        => $delete_guest_user,
        config_cluster           => true,
        cluster_disk_nodes       => $cluster_disk_nodes,
        wipe_db_on_cookie_change => true,
      }
    } else {
      class { $rabbitmq_class:
        service_ensure    => $service_ensure,
        port              => $port,
        delete_guest_user => $delete_guest_user,
      }
    }
    Class[$rabbitmq_class] -> Rabbitmq_user<| title == $userid |>
    Class[$rabbitmq_class] -> Rabbitmq_vhost<| title == $virtual_host |>
    # only configure nova after the queue is up
    Class[$rabbitmq_class] -> Anchor<| title == 'nova-start' |>
  }

  if ($enabled) {
    rabbitmq_vhost { $virtual_host:
      provider => 'rabbitmqctl',
    }
  }
}
