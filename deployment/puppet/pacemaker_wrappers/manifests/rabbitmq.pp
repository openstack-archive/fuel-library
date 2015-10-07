# == Class: pacemaker_wrappers::rabbitmq
#
# Overrides rabbitmq service provider as a pacemaker
#
# TODO(bogdando) that one just an example of Pacemaker service
#   provider wrapper implementation and should be moved to openstack_extra
#   and params should be described
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
class pacemaker_wrappers::rabbitmq (
  $primitive_type     = 'rabbitmq-server',
  $service_name       = $::rabbitmq::service_name,
  $port               = $::rabbitmq::port,
  $debug              = false,
  $ocf_script_file    = 'cluster/ocf/rabbitmq',
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

  $ms_metadata     = {
    'notify'      => 'true',
    # We shouldn't enable ordered start for parallel start of RA.
    'ordered'     => 'false',
    'interleave'  => 'true',
    'master-max'  => '1',
    'master-node-max' => '1',
    'target-role' => 'Master'
  }

  $operations      = {
    'monitor' => {
      'interval' => '30',
      'timeout'  => '180'
    },
    'monitor:Master' => { # name:role
      'role' => 'Master',
      # should be non-intercectable with interval from ordinary monitor
      'interval' => '27',
      'timeout'  => '180'
    },
    'monitor:Slave'  => {
      'role'            => 'Slave',
      'interval'        => '103',
      'timeout'         => '180',
      'OCF_CHECK_LEVEL' => '30'
    },
    'start'     => {
      'timeout' => '360'
    },
    'stop' => {
      'timeout' => '120'
    },
    'promote' => {
      'timeout' => '120'
    },
    'demote' => {
      'timeout' => '120'
    },
    'notify' => {
      'timeout' => '180'
    },
  }

  pacemaker_wrappers::service { $service_name :
    primitive_type      => $primitive_type,
    complex_type        => 'master',
    metadata            => $metadata,
    ms_metadata         => $ms_metadata,
    operations          => $operations,
    parameters          => $parameters,
    #    ocf_script_file     => $ocf_script_file,
  }
  Service[$service_name] -> Rabbitmq_user <||>
}
