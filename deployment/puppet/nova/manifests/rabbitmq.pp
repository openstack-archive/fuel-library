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
  $cluster            = false,
  $cluster_disk_nodes = false,
  $enabled            = true,
  $rabbitmq_class     = 'rabbitmq::server',
  $rabbit_node_ip_address = 'UNSET',
  $ha_mode            = false,
  $primary_controller = false
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
    $service_enabled  = true
  } else {
    $service_ensure = 'stopped'
    $service_enabled  = false
  }

  if ($ha_mode) {
    $service_provider = 'pacemaker'
    $service_name     = 'p_rabbitmq-server'
  } else {
    $service_provider = undef
    $service_name     = 'rabbitmq-server'
  }

  if ($ha_mode and ! $primary_controller) {
    $real_delete_guest_user = false
  } else {
    $real_delete_guest_user = $delete_guest_user
  }

  if $cluster_disk_nodes {
    class { $rabbitmq_class:
      service_name             => $service_name,
      service_ensure           => $service_ensure,
      service_provider         => $service_provider,
      service_enabled          => $service_enabled,
      port                     => $port,
      delete_guest_user        => $real_delete_guest_user,
      config_cluster           => $cluster,
      cluster_disk_nodes       => $cluster_disk_nodes,
      wipe_db_on_cookie_change => true,
      version                  => $::openstack_version['rabbitmq_version'],
      node_ip_address          => $rabbit_node_ip_address,
    }

    if ($ha_mode) {
      # OCF script for pacemaker
      # and his dependences
      file {'rabbitmq-ocf':
        path   =>'/usr/lib/ocf/resource.d/mirantis/rabbitmq-server',
        mode   => '0755',
        owner  => root,
        group  => root,
        source => "puppet:///modules/nova/ocf/rabbitmq",
      }

      # Disable OS-aware service, because rabbitmq-server managed by Pacemaker.
      service {'rabbitmq-server__disabled':
        name       => 'rabbitmq-server',
        ensure     => 'stopped',
        enable     => false,
      }

      File<| title == 'ocf-mirantis-path' |> -> File['rabbitmq-ocf']
      Package['pacemaker'] -> File<| title == 'ocf-mirantis-path' |>
      Package['pacemaker'] -> File['rabbitmq-ocf']
      Package['rabbitmq-server'] ->
        Service['rabbitmq-server__disabled'] ->
          File['rabbitmq-ocf'] ->
            Service["$service_name"]
      if ($primary_controller) {
        cs_resource {"$service_name":
          ensure          => present,
          #cib             => 'rabbitmq',
          primitive_class => 'ocf',
          provided_by     => 'mirantis',
          primitive_type  => 'rabbitmq-server',
          parameters      => {
            'node_port'     => $port,
            #'debug'         => true,
          },
          metadata                 => {
             'migration-threshold' => 'INFINITY',
             'failure-timeout'     => '60s'

          },
          multistate_hash => {
            'type' => 'master',
          },
          ms_metadata => {
            'notify'      => 'true',
            'ordered'     => 'false', # We shouldn't enable ordered start for parallel start of RA.
            'interleave'  => 'true',  
            'master-max'  => '1',
            'master-node-max' => '1',
            'target-role' => 'Master'
          },
          operations => {
            'monitor' => {
              'interval' => '30',
              'timeout'  => '60'
            },
            'monitor:Master' => { # name:role
              'role' => 'Master',
              'interval' => '27', # should be non-intercectable with interval from ordinary monitor
              'timeout'  => '60'
            },
            'start' => {
              'timeout' => '120'
            },
            'stop' => {
              'timeout' => '60'
            },
            'promote' => {
              'timeout' => '120'
            },
            'demote' => {
              'timeout' => '60'
            },
            'notify' => {
              'timeout' => '60'
            },
          },
        }
        File['rabbitmq-ocf'] ->
          Cs_resource["$service_name"] ->
            Service["$service_name"]
      }

      Service["$service_name"] ->
          Rabbitmq_user <||>
    }
  } else {
    class { $rabbitmq_class:
      service_ensure    => $service_ensure,
      port              => $port,
      delete_guest_user => $delete_guest_user,
      config_cluster    => false,
      version           => $::openstack_version['rabbitmq_version'],
      node_ip_address   => $rabbit_node_ip_address,
    }
  }

  if ($enabled) {
    rabbitmq_vhost { $virtual_host:
      provider => 'rabbitmqctl',
      require  => Class[$rabbitmq_class],
    }
  }
}
