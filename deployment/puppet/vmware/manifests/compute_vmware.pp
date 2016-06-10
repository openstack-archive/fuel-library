#    Copyright 2015 Mirantis, Inc.

# FIXME(mattymo): Use standard class documentation format
# vmware::compute_vmware resource deploys nova-compute service and configures it for use
# with vmwareapi.VCDriver (vCenter server as hypervisor).  Depends on nova::params class.

# Variables:
# availability_zone_name - availability zone which nova-compute will be assigned
# vc_cluster             - name of vSphere cluster
# vc_host                - IP address or hostname of the vCenter server
# vc_user                - username for vCenter server
# vc_password            - password for vCenter server
# service_name           - name that will form hypervisor name together with
#                          'availability_zone_name' in nova-compute.conf
# current_node           - name of node that we are executing manifets (e.g. 'node-4')
# target_node            - name of node where nova-compute must be deployed
#                          if it matches current_node we are deploying nova-compute service
# datastore_regex        - regex that specifies vCenter datastores to use
# api_retry_count        - number of tries on failures
# use_quantum            - shows if neutron is enabled
# service_enabled        - manage nova-compute service (Default: false)

define vmware::compute_vmware(
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $current_node,
  $target_node,
  $vlan_interface,
  $datastore_regex    = undef,
  $api_retry_count    = 5,
  $maximum_objects    = 100,
  $nova_compute_conf  = '/etc/nova/nova-compute.conf',
  $task_poll_interval = 5.0,
  $use_linked_clone   = true,
  $wsdl_location      = undef,
  $service_enabled    = false,
)
{
  include ::nova::params

  if $service_enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  # We skip deployment if current node name is not same as target_node
  if ($target_node == $current_node) {
    # $cluster is used inside template
    $cluster = $name
    file { $nova_compute_conf:
      ensure  => present,
      content => template('vmware/nova-compute.conf.erb'),
      mode    => '0600',
      owner   => 'nova',
      group   => 'nova',
    }

    package { 'nova-compute':
      ensure => installed,
      name   => $::nova::params::compute_package_name,
    }

    package { 'python-oslo.vmware':
      ensure => installed,
    }

    service { 'nova-compute':
      ensure => $service_ensure,
      name   => $::nova::params::compute_service_name,
      enable => $service_enabled,
    }

    Package['python-oslo.vmware']->
    Package['nova-compute']->
    File[$nova_compute_conf]->
    Service['nova-compute']
  }
}
