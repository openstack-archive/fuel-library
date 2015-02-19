# == Class: cluster::ntp_ocf
#
# Configure OCF service for NTP managed by corosync/pacemaker
#
class cluster::ntp_ocf ( $primary_controller ) {
  $service_name = 'p_ntp'

  if $primary_controller {
    cs_resource { $service_name:
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => 'ns_ntp',
      complex_type    => 'clone',
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

  file {'ntp-ocf':
    path   =>'/usr/lib/ocf/resource.d/fuel/ns_ntp',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/cluster/ocf/ns_ntp',
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
