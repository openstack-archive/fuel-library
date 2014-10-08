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
#   Use the default for 1.x, use '::rabbitmq' for 3.x
#   Defaults to 'rabbitmq::server'
#
class nova::rabbitmq(
  $userid                     ='guest',
  $password                   ='guest',
  $port                       ='5672',
  $virtual_host               ='/',
  $cluster                    = false,
  $cluster_disk_nodes         = false,
  $enabled                    = true,
  $rabbitmq_class             = 'rabbitmq::server',
  # TODO(bogdando) contribute new param rabbitmq_module
  $rabbitmq_module              = '1.0',
  $rabbit_node_ip_address     = 'UNSET',
  # TODO(bogdando) use service_provider 'pacemaker' instead of confusing ha_mode
  $ha_mode                    = false,
  $primary_controller         = false,
  # TODO(bogdando) contribute new params below
  $config_kernel_variables    = {},
  $config_variables           = {},
  $environment_variables      = {},
  $cluster_partition_handling = 'ignore',
  $key_source                 = 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
  $key_content                = undef,
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

  # NOTE(bogdando) the class call should depend on rabbimq module version
  #   new one (>=4.0) should use new options, old one should not
  #   otherwise the call is not backward compatible and will fail for
  #   old (<4.0) rabbitmq modules
  if ($rabbitmq_module < '4.0') {
    $rabbitmq_class_real = $rabbitmq_class
  } else {
    $rabbitmq_class_real = '::rabbitmq'
  }

  if $cluster_disk_nodes {

    # NOTE(bogdando) new config_*, environment_*, cluster_*, default_*
    #  service_manage params could be used only with 'rabbitmq' class >=4.0
    if $rabbitmq_class_real == '::rabbitmq' {
      class { $rabbitmq_class_real:
        package_gpg_key            => $key_source,
        key_content                => $key_content,
        service_name               => $service_name,
        service_ensure             => $service_ensure,
        service_provider           => $service_provider,
        service_manage             => $service_enabled,
        default_user               => $userid,
        default_pass               => $password,
        port                       => $port,
        delete_guest_user          => $real_delete_guest_user,
        config_cluster             => $cluster,
        cluster_disk_nodes         => $cluster_disk_nodes,
        wipe_db_on_cookie_change   => true,
        version                    => $::openstack_version['rabbitmq_version'],
        node_ip_address            => $rabbit_node_ip_address,
        config_kernel_variables    => $config_kernel_variables,
        config_variables           => $config_variables,
        environment_variables      => $environment_variables,
        cluster_partition_handling => $cluster_partition_handling,
      }
    } else {
      # backwards compatible call for rabbit class
      class { $rabbitmq_class_real:
        service_ensure           => $service_ensure,
        port                     => $port,
        delete_guest_user        => $delete_guest_user,
        config_cluster           => true,
        cluster_disk_nodes       => $cluster_disk_nodes,
        wipe_db_on_cookie_change => true,
      }
    }

    if ($ha_mode) {
      # NOTE(bogdando) pacemaker service provider wrapper usage example, will:
      #   1) stop OS-aware rabbitmq service defined by rabbitmq::service
      #   in order to put the service under OCF control plane as a
      #   pacemaker resource
      #   2) configure pacemaker resource for rabbitmq service  and start it
      class { 'nova::rabbitmq_pacemaker' :
        service_provider   => $service_provider,
        service_name       => $service_name,
        primary_controller => $primary_controller,
        port               => $port,
      }
    }
  } else {
    # clusterless mode
    if $rabbitmq_class_real == '::rabbitmq' {
      class { $rabbitmq_class_real:
        package_gpg_key         => $key_source,
        key_content             => $key_content,
        service_ensure          => $service_ensure,
        default_user            => $userid,
        default_pass            => $password,
        port                    => $port,
        delete_guest_user       => $delete_guest_user,
        config_cluster          => false,
        version                 => $::openstack_version['rabbitmq_version'],
        node_ip_address         => $rabbit_node_ip_address,
        config_kernel_variables => $config_kernel_variables,
        config_variables        => $config_variables,
        environment_variables   => $environment_variables,
      }
    } else {
      # backwards compatible call
      class { $rabbitmq_class_real:
        service_ensure    => $service_ensure,
        port              => $port,
        delete_guest_user => $delete_guest_user,
      }
    }
  }

  if ($enabled) {
    rabbitmq_vhost { $virtual_host:
      provider => 'rabbitmqctl',
      require  => Class[$rabbitmq_class],
    }
  }
}
