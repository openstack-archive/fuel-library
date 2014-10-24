# == Class: cluster::dns_ocf
#
# Configure OCF service for DNS managed by corosync/pacemaker
#
class cluster::dns_ocf ( $primary_controller ) {
  $service_name = 'p_dns'

  if $primary_controller {
    cs_resource { $service_name:
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'ns_dns',
      multistate_hash => {
        'type' => 'clone',
      },
      ms_metadata => {
        'interleave' => 'true',
      },
      metadata => {
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters => {
        'ns' => 'haproxy',
      },
      operations => {
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
    }
  Cs_resource[$service_name] ~> Service[$service_name]
  }

  file {'dns-ocf':
    path   =>'/usr/lib/ocf/resource.d/mirantis/ns_dns',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/cluster/ns_dns',
  } ~>

  service { $service_name:
    name       => $service_name,
    enable     => true,
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
    provider   => 'pacemaker',
  }
}
