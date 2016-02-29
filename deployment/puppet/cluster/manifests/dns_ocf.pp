# == Class: cluster::dns_ocf
#
# Configure OCF service for DNS managed by corosync/pacemaker
#
class cluster::dns_ocf {
  $service_name       = 'p_dns'
  $primitive_class    = 'ocf'
  $primitive_provider = 'fuel'
  $primitive_type     = 'ns_dns'
  $complex_type       = 'clone'
  $complex_metadata   = {
    'interleave' => 'true',
  }
  $metadata           = {
    'migration-threshold' => '3',
    'failure-timeout'     => '120',
  }
  $parameters         = {
    'ns' => 'vrouter',
  }
  $operations         = {
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

  pacemaker::service { $service_name :
    primitive_class    => $primitive_class,
    primitive_provider => $primitive_provider,
    primitive_type     => $primitive_type,
    complex_type       => $complex_type,
    complex_metadata   => $complex_metadata,
    metadata           => $metadata,
    parameters         => $parameters,
    operations         => $operations,
    prefix             => false,
  }

  pcmk_colocation { 'dns-with-vrouter-ns' :
    ensure => 'present',
    score  => 'INFINITY',
    first  => "clone_p_vrouter",
    second => "clone_${service_name}",
  }

  Pcmk_resource[$service_name] ->
  Pcmk_colocation['dns-with-vrouter-ns'] ->
  Service[$service_name]

  service { $service_name:
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

}
