$use_vcenter = hiera('use_vcenter', false)

include nova::params

if $use_vcenter{
  nova_config { 'DEFAULT/multi_host': value => 'False' } ~>
  Service['nova-network'] ~>
  Service['nova-compute']
  service { 'nova-network' :
    name   => $::nova::params::network_service_name,
    ensure => stopped,
    enable => false,
  }

  service { 'nova-compute':
    name   => $::nova::params::compute_service_name,
  }
}
