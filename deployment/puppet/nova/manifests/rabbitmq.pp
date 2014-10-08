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
# [*rabbitmq_module*]
#   (optional) The version of puppet-rabbitmq module
#   to use. Implies the rabbitmq_class value and class
#   param to be passed for it
#   Defaults to '1.0'
#
# [*node_ip_address*]
#   (optional) The value of RABBITMQ_NODE_IP_ADDRESS for new
#   versions ofpuppet-rabbitmq module
#   Defaults to 'UNSET'
#
# [*config_kernel_variables*]
#   (optional) The kernel config stanza for new versions of
#   puppet-rabbitmq module
#   Defaults to {}
#
# [*config_variables*]
#   (optional) The config stanza for new versions of
#   puppet-rabbitmq module
#   Defaults to {}
#
# [*environment_variables*]
#   (optional) The environment variables config stanza for
#   new versions of puppet-rabbitmq module
#   Defaults to {}
#
# [*cluster_partition_handling*]
#   (optional) The cluster partition handling method for
#   new versions of puppet-rabbitmq module
#   Defaults to 'ignore'
#
# [*key_source*]
#   (optional) The package key source for new versions of
#   puppet-rabbitmq module
#   Defaults to 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc'
#
# [*key_content*]
#   (optional) The package key content for new versions of
#   puppet-rabbitmq module. Overrides key_source, if specified.
#   Defaults to False
#
# [*version*]
#   (optional) The desired version of RabbitMQ to be installed
#   by new puppet-rabbitmq module
#   Defaults to '3.3.0'
#
class nova::rabbitmq(
  $userid                     ='guest',
  $password                   ='guest',
  $port                       ='5672',
  $virtual_host               ='/',
  $cluster_disk_nodes         = false,
  $enabled                    = true,
  $rabbitmq_class             = 'rabbitmq::server',
  $rabbitmq_module            = '1.0',
  $node_ip_address            = 'UNSET',
  $config_kernel_variables    = {},
  $config_variables           = {},
  $environment_variables      = {},
  $cluster_partition_handling = 'ignore',
  $key_source                 = 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
  $key_content                = false,
  # NOTE(bogdando) https://review.openstack.org/#/c/127087
  $version                    = '3.3.0',
) {

  # NOTE(bogdando) the class call should depend on rabbimq module version
  #   new one may use new options, old one should not.
  #   Otherwise, the call would not be backward compatible and would fail for
  #   old rabbitmq modules
  if ($rabbitmq_module < '4.0') {
    $rabbitmq_class_real = $rabbitmq_class
  } else {
    $rabbitmq_class_real = '::rabbitmq'
  }

  # only configure nova after the queue is up
  Class[$rabbitmq_class_real] -> Anchor<| title == 'nova-start' |>

  if ($enabled) {
    if $userid == 'guest' {
      $delete_guest_user = false
    } else {
      $delete_guest_user = true
      rabbitmq_vhost { $virtual_host:
        ensure   => present,
        provider => 'rabbitmqctl',
        require  => Class[$rabbitmq_class_real],
      }
      rabbitmq_user { $userid:
        ensure    => present,
        admin     => true,
        password  => $password,
        provider  => 'rabbitmqctl',
        require   => Rabbitmq_vhost[$virtual_host],
      }
      # I need to figure out the appropriate permissions
      rabbitmq_user_permissions { "${userid}@${virtual_host}":
        ensure               => present,
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        require              =>  Rabbitmq_user[$userid],
      }->Anchor<| title == 'nova-start' |>
    }
    $service_ensure = 'running'
    $service_enabled  = true
  } else {
    $service_ensure = 'stopped'
    $service_enabled  = false
  }

  if $cluster_disk_nodes {

    # NOTE(bogdando) new config_*, environment_*, cluster_*, default_*
    #  service_manage params could be used only with '::rabbitmq' class >=4.0
    if $rabbitmq_class_real == '::rabbitmq' {
      class { $rabbitmq_class_real:
        package_gpg_key            => $key_source,
        key_content                => $key_content,
        service_ensure             => $service_ensure,
        service_manage             => $service_enabled,
        port                       => $port,
        delete_guest_user          => $delete_guest_user,
        config_cluster             => true,
        cluster_disk_nodes         => $cluster_disk_nodes,
        wipe_db_on_cookie_change   => true,
        version                    => $version,
        node_ip_address            => $node_ip_address,
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
  } else {
    # clusterless mode
    if $rabbitmq_class_real == '::rabbitmq' {
      class { $rabbitmq_class_real:
        package_gpg_key         => $key_source,
        key_content             => $key_content,
        service_ensure          => $service_ensure,
        service_manage          => $service_enabled,
        port                    => $port,
        delete_guest_user       => $delete_guest_user,
        config_cluster          => false,
        version                 => $version,
        node_ip_address         => $node_ip_address,
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
}
