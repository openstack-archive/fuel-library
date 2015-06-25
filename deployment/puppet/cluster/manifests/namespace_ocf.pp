# == Class: cluster::namespace_ocf
#
# Configure OCF service for namespaces managed by corosync/pacemaker
#
define cluster::namespace_ocf (
  $primary_controller,
  $namespace = $name,
  $host_interface,
  $namespace_interface,
  $host_ip,
  $namespace_ip,
  $other_networks = false,
) {
  if $primary_controller {
    cs_resource { "p_${namespace}":
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => "ns-${namespace}",
      complex_type    => 'clone',
      ms_metadata     => {
        'interleave' => true,
      },
      metadata        => {
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters      => {
        'ns'                  => $namespace,
        'host_interface'      => $host_interface,
        'namespace_interface' => $namespace_interface,
        'host_ip'             => $host_ip,
        'namespace_ip'        => $namespace_ip,
        'other_networks'      => "'$other_networks'",
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

  Cs_resource["p_${namespace}"] -> Service["p_${namespace}"]
  }

  service { "p_${namespace}":
    ensure     => 'running',
    name       => "p_${namespace}",
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => 'pacemaker',
  }
}
