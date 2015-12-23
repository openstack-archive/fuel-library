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

  # $default_log_levels gets used in template file. Do not remove.
  if $debug {
    # Enable debug for rabbit and vmware only
    $default_log_levels = 'amqp=DEBUG,amqplib=DEBUG,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=DEBUG'
  } else {
    $default_log_levels = 'amqp=WARN,amqplib=WARN,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=WARN'
  }

  $vsphere_clusters = vmware_index($vcenter_cluster)

  include ceilometer::params

  package { 'ceilometer-agent-compute':
    ensure => present,
    name   => $::ceilometer::params::agent_compute_package_name,
  }

  create_resources(vmware::ceilometer::ha, parse_vcenter_settings($vcenter_settings))

  Package['ceilometer-agent-compute']->
  Vmware::Ceilometer::Ha<||>
}
