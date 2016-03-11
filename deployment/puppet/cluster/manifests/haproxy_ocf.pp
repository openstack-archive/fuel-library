# == Class: cluster::haproxy_ocf
#
# Configure OCF service for HAProxy managed by corosync/pacemaker
#
class cluster::haproxy_ocf (
  $debug            = false,
  $other_networks   = false,
  $colocate_haproxy = true,
) inherits cluster::haproxy {
  $primitive_type  = 'ns_haproxy'
  $complex_type    = 'clone'
  $complex_metadata     = {
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
      'timeout' => '60'
    },
    'stop'    => {
      'timeout' => '60'
    },
  }

  pacemaker::service { $service_name :
    primitive_type   => $primitive_type,
    parameters       => $parameters,
    metadata         => $metadata,
    operations       => $operations,
    complex_metadata => $complex_metadata,
    complex_type     => $complex_type,
    prefix           => false,
  }

  if $colocate_haproxy {
    pcmk_colocation { 'vip_public-with-haproxy':
      ensure     => 'present',
      score      => 'INFINITY',
      first      => "clone_${service_name}",
      second     => "vip__public",
    }
    Service[$service_name] -> Pcmk_colocation['vip_public-with-haproxy']

    pcmk_colocation { 'vip_management-with-haproxy':
      ensure     => 'present',
      score      => 'INFINITY',
      first      => "clone_${service_name}",
      second     => 'vip__management',
    }
    Service[$service_name] -> Pcmk_colocation['vip_management-with-haproxy']
  }

  Pcmk_resource[$service_name] ->
  Service[$service_name]
}


