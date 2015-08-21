# == Class: cluster::vrouter_ocf
#
# Configure OCF service for vrouter managed by corosync/pacemaker
#
class cluster::vrouter_ocf (
  $other_networks = false,
) {
  $service_name = 'p_vrouter'

  $primitive_type = 'ns_vrouter'
  $complex_type   = 'clone'
  $ms_metadata = {
    'interleave' => true,
  }
  $metadata = {
    'migration-threshold' => '3',
    'failure-timeout'     => '120',
  }
  $parameters = {
    'ns'             => 'vrouter',
    'other_networks' => "${other_networks}",
  }
  $operations = {
    'monitor' => {
      'interval' => '30',
      'timeout'  => '60'
    },
    'start'   => {
      'timeout' => '30'
    },
    'stop'    => {
      'timeout' => '60'
    },
  }

  service { $service_name :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => 'pacemaker',
  }

  pacemaker_wrappers::service { $service_name :
    primitive_type => $primitive_type,
    parameters     => $parameters,
    metadata       => $metadata,
    operations     => $operations,
    ms_metadata    => $ms_metadata,
    complex_type   => $complex_type,
    prefix         => false,
  }
}
