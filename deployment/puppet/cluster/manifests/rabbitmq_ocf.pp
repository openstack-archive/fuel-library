# == Class: cluster::rabbitmq_ocf
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
# [*host_ip*]
#   String. A string used for OCF script to collect
#   RabbitMQ statistics
#   Defaults to '127.0.0.1'
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
# [*enable_rpc_ha*]
#   Boolean. Set ha-mode=all policy for RPC queues. Note that
#   Ceilometer queues are not affected by this flag.
#
# [*enable_notifications_ha*]
#   Boolean. Set ha-mode=all policy for Ceilometer queues. Note
#   that RPC queues are not affected by this flag.
#
# [*fqdn_prefix*]
#   String. Optional FQDN prefix for node names.
#   Defaults to empty string
#
# [*policy_file*]
#   String. Optional path to the policy file for HA queues.
#   Defaults to undef
#
# [*start_timeout*]
#   String. Optional op start timeout for lrmd.
#   Defaults to '120'
#
# [*stop_timeout*]
#   String. Optional op stop timeout for lrmd.
#   Defaults to '120'
#
# [*mon_timeout*]
#   String. Optional op monitor timeout for lrmd.
#   Defaults to '120'
#
# [*promote_timeout*]
#   String. Optional op promote timeout for lrmd.
#   Defaults to '120'
#
# [*demote_timeout*]
#  String. Optional op demote timeout for lrmd.
#   Defaults to '120'
#
# [*notify_timeout*]
#   String. Optional op demote timeout for lrmd.
#   Defaults to '120'
#
# [*master_mon_interval*]
#   String. Optional op master's monitor interval for lrmd.
#   Should be different from mon_interval. Defaults to '27'
#
# [*mon_interval*]
#   String. Optional op slave's monitor interval for lrmd.
#   Defaults to 30
#
class cluster::rabbitmq_ocf (
  $primitive_type          = 'rabbitmq-server',
  $service_name            = $::rabbitmq::service_name,
  $port                    = $::rabbitmq::port,
  $host_ip                 = '127.0.0.1',
  $debug                   = false,
  $ocf_script_file         = 'cluster/ocf/rabbitmq',
  $command_timeout         = '',
  $erlang_cookie           = 'EOKOWXQREETZSHFNTPEY',
  $admin_user              = undef,
  $admin_pass              = undef,
  $enable_rpc_ha           = false,
  $enable_notifications_ha = true,
  $fqdn_prefix             = '',
  $pid_file                = undef,
  $policy_file             = undef,
  $start_timeout           = '120',
  $stop_timeout            = '120',
  $mon_timeout             = '120',
  $promote_timeout         = '120',
  $demote_timeout          = '120',
  $notify_timeout          = '120',
  $master_mon_interval     = '27',
  $mon_interval            = '30',
) inherits ::rabbitmq::service {

  if $host_ip == 'UNSET' or $host_ip == '0.0.0.0' {
    $real_host_ip = '127.0.0.1'
  } else {
    $real_host_ip = $host_ip
  }

  $parameters      = {
    'host_ip'                 => $real_host_ip,
    'node_port'               => $port,
    'debug'                   => $debug,
    'command_timeout'         => $command_timeout,
    'erlang_cookie'           => $erlang_cookie,
    'admin_user'              => $admin_user,
    'admin_password'          => $admin_pass,
    'enable_rpc_ha'           => $enable_rpc_ha,
    'enable_notifications_ha' => $enable_notifications_ha,
    'fqdn_prefix'             => $fqdn_prefix,
    'pid_file'                => $pid_file,
    'policy_file'             => $policy_file,
  }

  $metadata        = {
    'migration-threshold' => '10',
    'failure-timeout'     => '30s',
    'resource-stickiness' => '100',
  }

  $complex_metadata     = {
    'notify'      => true,
    # We shouldn't enable ordered start for parallel start of RA.
    'ordered'     => false,
    'interleave'  => true,
    'master-max'  => '1',
    'master-node-max' => '1',
    'target-role' => 'Master',
    'requires'    => 'nothing'
  }

  $operations      = {
    'monitor' => {
      'interval' => $mon_interval,
      'timeout'  => $mon_timeout
    },
    'monitor:Master' => { # name:role
      'role' => 'Master',
      'interval' => $master_mon_interval,
      'timeout'  => $mon_timeout
    },
    'start'     => {
      'interval' => '0',
      'timeout'  => $start_timeout
    },
    'stop' => {
      'interval' => '0',
      'timeout'  => $stop_timeout
    },
    'promote' => {
      'interval' => '0',
      'timeout'  => $promote_timeout
    },
    'demote' => {
      'interval' => '0',
      'timeout'  => $demote_timeout
    },
    'notify' => {
      'interval' => '0',
      'timeout'  => $notify_timeout
    },
  }

  pacemaker::service { $service_name :
    primitive_type   => $primitive_type,
    complex_type     => 'master',
    complex_metadata => $complex_metadata,
    metadata         => $metadata,
    operations       => $operations,
    parameters       => $parameters,
    #ocf_script_file => $ocf_script_file,
  }

  if !defined(Service_status['rabbitmq']) {
    ensure_resource('service_status', ['rabbitmq'],
      { 'ensure' => 'online', 'check_cmd' => 'rabbitmqctl node_health_check && rabbitmqctl cluster_status'})
  } else {
    Service_status<| title == 'rabbitmq' |> {
        check_cmd => 'rabbitmqctl node_health_check && rabbitmqctl cluster_status',
    }
  }

  Service[$service_name] -> Service_status['rabbitmq']
}
