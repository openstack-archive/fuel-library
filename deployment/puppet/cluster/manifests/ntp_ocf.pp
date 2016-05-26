# == Class: cluster::ntp_ocf
#
# Configure OCF service for NTP managed by corosync/pacemaker
#
class cluster::ntp_ocf inherits ntp::params {
  $primitive_type = 'ns_ntp'
  $primitive_provider = 'fuel'
  $complex_type = 'clone'

  $complex_metadata = {
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
      'interval' => '0',
      'timeout'  => '30'
    },
    'stop' => {
      'interval' => '0',
      'timeout'  => '30'
    },
  }

  pacemaker_colocation { 'ntp-with-vrouter-ns' :
    ensure => 'present',
    score  => 'INFINITY',
    first  => 'vrouter-clone',
    second => "${service_name}-clone",
  }

  pacemaker::new::wrapper { $service_name :
    primitive_type     => $primitive_type,
    primitive_provider => $primitive_provider,
    parameters         => $parameters,
    metadata           => $metadata,
    operations         => $operations,
    complex_metadata   => $complex_metadata,
    complex_type       => $complex_type,
  }

  Pacemaker_resource[$service_name] ->
  Pacemaker_colocation['ntp-with-vrouter-ns'] ->
  Service['ntp']

  if ! defined(Service[$service_name]) {
    service { $service_name:
      name       => $service_name,
      enable     => true,
      ensure     => 'running',
      hasstatus  => true,
      hasrestart => true,
    }
  }

}
