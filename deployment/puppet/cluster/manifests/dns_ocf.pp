# == Class: cluster::dns_ocf
#
# Configure OCF service for DNS managed by corosync/pacemaker
#
class cluster::dns_ocf ( $primary_controller ) {
  $service_name = 'p_dns'

  if $primary_controller {
    pcmk_resource { $service_name:
      ensure             => 'present',
      primitive_class    => 'ocf',
      primitive_provider => 'fuel',
      primitive_type     => 'ns_dns',
      complex_type       => 'clone',
      complex_metadata   => {
        'interleave' => 'true',
      },
      metadata           => {
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters         => {
        'ns' => 'vrouter',
      },
      operations         => {
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
      },
    } ->

    pcmk_colocation { 'dns-with-vrouter-ns':
      ensure     => 'present',
      score      => 'INFINITY',
      first      => "clone_p_vrouter",
      second     => "clone_${service_name}",
    }

    Pcmk_resource[$service_name] ~> Service[$service_name]
  }

  service { $service_name:
    name       => $service_name,
    enable     => true,
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
    provider   => 'pacemaker',
  }
}
