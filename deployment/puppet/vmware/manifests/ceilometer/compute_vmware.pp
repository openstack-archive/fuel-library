class vmware::ceilometer::compute_vmware(
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $target_node = undef,
  $datastore_regex = undef,
) {
  ceilometer_config {
    'DEFAULT/hypervisor_inspector': value => 'vmware';
    'DEFAULT/host':                 value => "${availability_zone_name}-${service_name}";
    'vmware/host_ip':               value => $vc_host;
    'vmware/host_username':         value => $vc_user;
    'vmware/host_password':         value => $vc_password;
  }

  file { '/etc/ceilometer/ceilometer.conf':
    mode => '0600',
  }

  include ceilometer::params

  service { 'ceilometer-agent-compute':
    name   => $::ceilometer::params::agent_compute_service_name,
  }

  Ceilometer_config<| |>->
  File['/etc/ceilometer/ceilometer.conf']~>
  Service['ceilometer-polling']
}
