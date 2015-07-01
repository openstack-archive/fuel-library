# == Class: cluster::ntp_ocf
#
# Configure OCF service for NTP managed by corosync/pacemaker
#
class cluster::ntp_ocf ( ) {
  include ntp::params

  $basic_service_name = $ntp::params::service_name
  $service_name = "p_${basic_service_name}"

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
      'ns' => 'vrouter',
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
  } ->

  cs_rsc_colocation { 'ntpd-with-vrouter-ns':
    ensure     => present,
    score      => 'INFINITY',
    primitives => [
      "clone_${service_name}",
      "clone_p_vrouter"
    ],
  }

  Cs_resource[$service_name] ~> Service[$service_name]

  #  file {'ntp-ocf':
  #  path   =>'/usr/lib/ocf/resource.d/fuel/ns_ntp',
  #  mode   => '0755',
  #  owner  => root,
  #  group  => root,
  #  source => 'puppet:///modules/cluster/ocf/ns_ntp',
  #} ~>

  service { $service_name:
    name     => $service_name,
    enable   => true,
    ensure   => 'running',
    provider => 'pacemaker',
  }
}
