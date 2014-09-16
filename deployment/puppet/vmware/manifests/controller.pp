#    Copyright 2014 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

# modules needed: nova
# limitations:
# - only one vcenter supported

class vmware::controller (
  $api_retry_count = 5,
  $datastore_regex = undef,
  $amqp_port = '5673',
  $compute_driver = 'vmwareapi.VMwareVCDriver',
  $ensure_package = 'present',
  $ha_mode = false,
  $maximum_objects = 100,
  $nova_conf = '/etc/nova/nova.conf',
  $task_poll_interval = 5.0,
  $vcenter_cluster = 'cluster',
  $vcenter_host_ip = '10.10.10.10',
  $vcenter_user = 'user',
  $vcenter_password = 'password',
  $vlan_interface = undef,
  $vnc_address = '0.0.0.0',
  $use_linked_clone = true,
  $use_quantum = false,
  $wsdl_location = undef
)
{
  include nova

  # Split provided string with cluster names and enumerate items.
  # Index is used to form file names on host system, e.g.
  # /etc/sysconfig/nova-compute-vmware-0
  $vsphere_clusters = vmware_index($vcenter_cluster)

  # install the nova-compute service
  nova::generic_service { 'compute':
	  enabled        => false,
	  package_name   => $::nova::params::compute_package_name,
	  service_name   => $::nova::params::compute_service_name,
	  ensure_package => $ensure_package,
	  before         => Exec['networking-refresh']
  }

  if ! $ha_mode {
    create_resources(vmware::compute::simple, $vsphere_clusters)

    Nova::Generic_service['compute']->
    Vmware::Compute::Simple<| |>
  } else {

    file { 'vcenter-nova-compute-ocf':
      path   => '/usr/lib/ocf/resource.d/mirantis/nova-compute',
      source => 'puppet:///modules/vmware/ocf/nova-compute',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    # Create nova-compute per vsphere cluster
    create_resources(vmware::compute::ha, $vsphere_clusters)

    Nova::Generic_service['compute']->
    anchor { 'vmware-nova-compute-start': }->
    File['vcenter-nova-compute-ocf']->
    Vmware::Compute::Ha<||>->
    anchor { 'vmware-nova-compute-end': }
  }

  # network configuration
  class { 'vmware::network':
    use_quantum => $use_quantum,
    ha_mode     => $ha_mode
  }

  # Enable metadata service on Controller node
  Nova_config <| title == 'DEFAULT/enabled_apis' |> {
    value => 'ec2,osapi_compute,metadata'
  }
  # Set correct parameter for vnc access
  nova_config {
    'DEFAULT/novncproxy_base_url': value => "http://${vnc_address}:6080/vnc_auto.html"
  }

  # install cirros vmdk package
  package { 'cirros-testvmware':
    ensure => present
  }
  package { 'python-suds':
    ensure => present
  }
}
