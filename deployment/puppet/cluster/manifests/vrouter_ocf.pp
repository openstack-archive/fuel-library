# == Class: cluster::vrouter_ocf
#
# Configure OCF service for vrouter managed by corosync/pacemaker
#
class cluster::vrouter_ocf (
  $primary_controller,
  $other_networks = false,
){
  $service_name = 'p_vrouter'

  file {'/usr/lib/ocf/resource.d/fuel/ns_vrouter':
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/cluster/ocf/ns_vrouter',
  }

  if $primary_controller {
    cs_resource { $service_name:
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => 'ns_vrouter',
      complex_type    => 'clone',
      ms_metadata     => {
        'interleave' => true,
      },
      metadata        => {
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters      => {
        'ns'             => 'vrouter',
        'other_networks' => "'$other_networks'",
      },
      operations      => {
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
      },
    }

  File['/usr/lib/ocf/resource.d/fuel/ns_vrouter'] -> Cs_resource[$service_name]
  Cs_resource[$service_name] -> Service[$service_name]
  }

  File['/usr/lib/ocf/resource.d/fuel/ns_vrouter'] ~> Service[$service_name]

  service { $service_name:
    ensure     => 'running',
    name       => $service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => 'pacemaker',
  }
}
