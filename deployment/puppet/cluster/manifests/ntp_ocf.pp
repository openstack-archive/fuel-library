# == Class: cluster::ntp_ocf
#
# Configure OCF service for NTP managed by corosync/pacemaker
#
class cluster::ntp_ocf inherits ntp::params {
  $primitive_type = 'ns_ntp'
  $complex_type   = 'clone'

  $ms_metadata = {
    'interleave' => 'true',
  }

  $metadata = {
    'migration-threshold' => '3',
    'failure-timeout'     => '120',
  }

  $parameters = {
    'ns' => 'vrouter',
  }

  $operations = {
    'monitor' => {
      'interval' => '20',
      'timeout'  => '10'
    },
    'start' => {
      'timeout' => '30'
    },
    'stop' => {
      'timeout' => '30'
    },
  }

  cs_rsc_colocation { 'ntp-with-vrouter-ns' :
    ensure     => 'present',
    score      => 'INFINITY',
    primitives => [
      "clone_p_$service_name",
      "clone_p_vrouter",
    ],
  }

  pacemaker_wrappers::service { $service_name :
    primitive_type => $primitive_type,
    parameters     => $parameters,
    metadata       => $metadata,
    operations     => $operations,
    ms_metadata    => $ms_metadata,
    complex_type   => $complex_type,
    prefix         => true,
  }

  Cs_rsc_colocation['ntp-with-vrouter-ns'] -> Service['ntp']

}
