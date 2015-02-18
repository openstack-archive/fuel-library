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

  class { 'ceilometer::agent::compute':
    enabled => false,
  }

  $vsphere_clusters = vmware_index($vcenter_cluster)

  file {'ceilometer-agent-compute-ocf':
    path   =>'/usr/lib/ocf/resource.d/fuel/ceilometer-agent-compute',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/vmware/ocf/ceilometer-agent-compute',
  }

  if $vcenter_settings {
    # Fixme! This a temporary workaround to keep existing functioanality
    # After fully implementation of the multi HV support it is need to rename resource
    # back to vmware::ceilometer::ha
    create_resources(vmware::ceilometer::ha_multi_hv, parse_vcenter_settings($vcenter_settings))

    Class['ceilometer::agent::compute']->
    File['ceilometer-agent-compute-ocf']->
    Vmware::Ceilometer::Ha_multi_hv<||>
  } else {
    create_resources(vmware::ceilometer::ha, $vsphere_clusters)

    Class['ceilometer::agent::compute']->
    File['ceilometer-agent-compute-ocf']->
    Vmware::Ceilometer::Ha<||>
  }
}
