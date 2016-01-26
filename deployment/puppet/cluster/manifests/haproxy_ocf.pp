# == Class: cluster::haproxy_ocf
#
# Configure OCF service for HAProxy managed by corosync/pacemaker
#
class cluster::haproxy_ocf (
  $debug = false,
  $other_networks = false,
) inherits cluster::haproxy {

  $primitive_type  = 'ns_haproxy'
  $complex_type    = 'clone'

  $ms_metadata     = {
    'interleave' => true,
  }

  $metadata        = {
    'migration-threshold' => '3',
    'failure-timeout'     => '120',
  }

  $parameters      = {
    'ns'             => 'haproxy',
    'debug'          => $debug,
    'other_networks' => $other_networks,
  }

  $operations      = {
    'monitor' => {
      'interval' => '30',
      'timeout'  => '60'
    },
      'start'   => {
        'interval' => '0',
        'timeout'  => '60'
      },
      'stop'    => {
        'interval' => '0',
        'timeout'  => '60'
      },
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

  cs_rsc_colocation { 'vip_public-with-haproxy':
    ensure     => present,
    score      => 'INFINITY',
    primitives => [
        "vip__public",
        "clone_${service_name}"
    ],
  }
  cs_rsc_colocation { 'vip_management-with-haproxy':
    ensure     => present,
    score      => 'INFINITY',
    primitives => [
        "vip__management",
        "clone_${service_name}"
    ],
  }

  Cs_resource[$service_name] -> Cs_rsc_colocation['vip_public-with-haproxy'] -> Service[$service_name]
  Cs_resource[$service_name] -> Cs_rsc_colocation['vip_management-with-haproxy'] -> Service[$service_name]

}


