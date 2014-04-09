#
# class for installing rabbitmq server for nova
#
#
# ==Parameters
#
# [cluster_disk_nodes] Enables/disables RabbitMQ clustering.  Specify an array of Rabbit Broker
#   IP addresses to configure clustering. Optional.
#   Defaults to false.
#
class nova::rabbitmq(
  $userid             ='guest',
  $password           ='guest',
  $port               ='5672',
  $virtual_host       ='/',
  $cluster_disk_nodes = false,
  $enabled            = true
) {

  # only configure nova after the queue is up
  Class['rabbitmq::service'] -> Anchor<| title == 'nova-start' |>

  if ($enabled) {
    if $userid == 'guest' {
      $delete_guest_user = false
    } else {
      $delete_guest_user = true
      rabbitmq_user { $userid:
        admin     => true,
        password  => $password,
        provider  => 'rabbitmqctl',
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
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if $cluster_disk_nodes {
    class { 'rabbitmq::server':
      service_ensure           => $service_ensure,
      port                     => $port,
      delete_guest_user        => $delete_guest_user,
      config_cluster           => true,
      cluster_disk_nodes       => $cluster_disk_nodes,
      wipe_db_on_cookie_change => true,
    }
  } else {
    class { 'rabbitmq::server':
      service_ensure    => $service_ensure,
      port              => $port,
      delete_guest_user => $delete_guest_user,
    }
  }

  if ($enabled) {
    rabbitmq_vhost { $virtual_host:
      provider => 'rabbitmqctl',
      require  => Class['rabbitmq::server'],
    }
  }
}
