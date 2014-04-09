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
#   (optional) The rabbitmq puppet class to depend on,
#   which is dependent on the puppet-rabbitmq version.
#   Use the default for 1.x, use 'rabbitmq' for 3.x
#   Defaults to 'rabbitmq::server'
#
class nova::rabbitmq(
  $userid             ='guest',
  $password           ='guest',
  $port               ='5672',
  $virtual_host       ='/',
  $cluster_disk_nodes = false,
  $enabled            = true,
  $rabbitmq_class     = 'rabbitmq::server'
) {

  # only configure nova after the queue is up
  Class[$rabbitmq_class] -> Anchor<| title == 'nova-start' |>

  if ($enabled) {
    if $userid == 'guest' {
      $delete_guest_user = false
    } else {
      $delete_guest_user = true
      rabbitmq_user { $userid:
        admin     => true,
        password  => $password,
        provider  => 'rabbitmqctl',
        require   => Class[$rabbitmq_class],
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

  if ($enabled) {
    rabbitmq_vhost { $virtual_host:
      provider => 'rabbitmqctl',
      require  => Class[$rabbitmq_class],
    }
  }
}
