class vmware::ceilometer::compute_vmware(
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $target_node = undef,
  $datastore_regex = undef,
  $debug           = undef,
  $auth_uri        = undef,
  $auth_host       = undef,
  $auth_user       = undef,
  $auth_password   = undef,
  $tenant          = undef,
) {
  if $debug {
    # Enable debug for rabbit and vmware only
    $default_log_levels = 'amqp=DEBUG,amqplib=DEBUG,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=DEBUG'
  } else {
    $default_log_levels = 'amqp=WARN,amqplib=WARN,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=WARN'
  }

  ceilometer_config {
    'DEFAULT/default_log_levels':           value => $default_log_levels;
    'DEFAULT/hypervisor_inspector':         value => 'vsphere';
    'DEFAULT/host':                         value => "${availability_zone_name}-${service_name}";
    'vmware/host_ip':                       value => $vc_host;
    'vmware/host_username':                 value => $vc_user;
    'vmware/host_password':                 value => $vc_password;
    'keystone_authtoken/auth_uri':          value => $auth_uri;
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/admin_user':        value => $auth_user;
    'keystone_authtoken/admin_password':    value => $auth_password;
    'keystone_authtoken/admin_tenant_name': value => $tenant;
  }

  include ceilometer::params

  service { 'ceilometer-agent-compute':
    ensure => running,
    name   => $::ceilometer::params::agent_compute_service_name,
  }

  Ceilometer_config<| |> ~> Service['ceilometer-agent-compute']
}
