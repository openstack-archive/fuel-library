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
    cs_resource { "p_ns_${namespace}":
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => "IPnamespace",
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

  Cs_resource["p_ns_${namespace}"] -> Service["p_ns_${namespace}"]
  }

  service { "p_ns_${namespace}":
    ensure     => 'running',
    name       => "p_ns_${namespace}",
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => 'pacemaker',
  }
}
