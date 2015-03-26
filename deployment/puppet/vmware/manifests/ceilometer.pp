class vmware::ceilometer (
  $vcenter_settings     = undef,
  $vcenter_user         = 'user',
  $vcenter_password     = 'password',
  $vcenter_host_ip      = '10.10.10.10',
  $vcenter_cluster      = 'cluster',
  $hypervisor_inspector = 'vsphere',
  $api_retry_count      = '5',
  $task_poll_interval   = '5.0',
  $wsdl_location        = false,
  $debug                = false,
) {

  if $debug {
    # Enable debug for rabbit and vmware only
    $default_log_levels = 'amqp=DEBUG,amqplib=DEBUG,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=DEBUG'
  } else {
    $default_log_levels = 'amqp=WARN,amqplib=WARN,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=WARN'
  }

  $vsphere_clusters = vmware_index($vcenter_cluster)

  include ceilometer::params

  package { 'ceilometer-agent-compute':
    name   => $ceilometer::params::agent_compute_package_name,
    ensure => present
  }

  file { 'ceilometer-agent-compute-ocf':
    path   =>'/usr/lib/ocf/resource.d/fuel/ceilometer-agent-compute',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/vmware/ocf/ceilometer-agent-compute',
  }

  create_resources(vmware::ceilometer::ha_multi_hv, parse_vcenter_settings($vcenter_settings))

  Package['ceilometer-agent-compute']->
  File['ceilometer-agent-compute-ocf']->
  Vmware::Ceilometer::Ha_multi_hv<||>
}
