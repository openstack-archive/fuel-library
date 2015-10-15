# == Class: cluster::rabbitmq_ocf
#
# Overrides rabbitmq service provider as a pacemaker
#
# === Parameters
#
# [*primitive_type*]
#   String. Corosync resource primitive_type
#   Defaults to 'rabbitmq-server'
#
# [*service_name*]
#   String. The service name of rabbitmq.
#   Defaults to $::rabbitmq::service_name
#
# [*port*]
#   Integer. The port for rabbitmq to listen on.
#   Defaults to $::rabbitmq::port
#
# [*debug*]
#   Boolean. Flag to enable or disable debug logging.
#   Defaults to false;
# [*ocf_script_file*]
#   String. The script filename for use with pacemaker.
#   Defaults to 'cluster/ocf/rabbitmq'
#
# [*command_timeout*]
#   String.
#
# [*erlang_cookie*]
#   String. A string used as a cookie for rabbitmq instances to
#   communicate with eachother.
#   Defaults to 'EOKOWXQREETZSHFNTPEY'
#
# [*admin_user*]
#   String. An admin username that is used to import the rabbitmq
#   definitions from a backup as part of a recovery action.
#   Defaults to undef
#
# [*admin_pass*]
#   String. An admin password that is used to import the rabbitmq
#   definitions from a backup as part of a recovery action.
#   Defaults to undef
#
class cluster::rabbitmq_ocf (
  $primitive_type     = 'rabbitmq-server',
  $primitive_provider = 'rabbitmq',
  $service_name       = $::rabbitmq::service_name,
  $port               = $::rabbitmq::port,
  $debug              = false,
  $command_timeout    = '',
  $erlang_cookie      = 'EOKOWXQREETZSHFNTPEY',
  $admin_user         = undef,
  $admin_pass         = undef,
) inherits ::rabbitmq::service {

  $parameters      = {
    'node_port'       => $port,
    'debug'           => $debug,
    'command_timeout' => $command_timeout,
    'erlang_cookie'   => $erlang_cookie,
    'admin_user'      => $admin_user,
    'admin_password'  => $admin_pass,
  }

  $metadata        = {
    'migration-threshold' => '10',
    'failure-timeout'     => '30s',
    'resource-stickiness' => '100',
  }

  $operations      = {
    'monitor' => {
      'interval' => '20',
      'timeout'  => '180'
    },
    'start'     => {
      'timeout' => '360'
    },
    'stop' => {
      'timeout' => '120'
    },
  }

  pacemaker::service { $service_name :
    primitive_type           => $primitive_type,
    primitive_provider       => $primitive_provider,
    metadata                 => $metadata,
    operations               => $operations,
    parameters               => $parameters,
  }
  Service[$service_name] -> Rabbitmq_user <||>
  Class['rabbitmq::install'] -> Pcmk_resource <||>
}
