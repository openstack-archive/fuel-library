class vmware::ceilometer (
  $vcenter_user         = 'user',
  $vcenter_password     = 'password',
  $vcenter_host_ip      = '10.10.10.10',
  $vcenter_cluster      = 'cluster',
  $ha_mode              = false,
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

  if $ha_mode {
    file {'ceilometer-agent-compute-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/ceilometer-agent-compute',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => 'puppet:///modules/vmware/ocf/ceilometer-agent-compute',
    }

    create_resources(vmware::ceilometer::ha, $vsphere_clusters)

    Class['ceilometer::agent::compute']->
    File['ceilometer-agent-compute-ocf']->
    Vmware::Ceilometer::Ha<||>->

  } else {
    create_resources(vmware::ceilometer::simple, $vsphere_clusters)

    Class['ceilometer::agent::compute']->
    Vmware::Ceilometer::Simple<||>
  }
}
