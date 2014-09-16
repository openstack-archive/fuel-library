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
  $compute_driver = 'vmwareapi.VMwareVCDriver',
  $ensure_package = 'present',
  $ha_mode = false,
  $maximum_objects = 100,
  $nova_conf = '/etc/nova/nova.conf',
  $task_poll_interval = 5.0,
  $vcenter_user = 'user',
  $vcenter_password = 'password',
  $vcenter_host_ip = '10.10.10.10',
  $vcenter_cluster = 'cluster',
  $use_linked_clone = true,
  $use_quantum = false,
  $wsdl_location = undef
)
{
  if ! $ha_mode {
    $vsphere_clusters = split($vcenter_cluster, ",")

    vmware::compute::simple { $vsphere_clusters: }

    # install the nova-compute service
    nova::generic_service { 'compute':
      enabled        => false,
      package_name   => $::nova::params::compute_package_name,
      service_name   => $::nova::params::compute_service_name,
      ensure_package => $ensure_package,
      before         => Exec['networking-refresh']
    }

    Nova::Generic_service['compute']->
    Vmware::Compute::Simple<| |>
  } else {
    nova::generic_service { 'compute':
      enabled        => false,
      package_name   => $::nova::params::compute_package_name,
      service_name   => $::nova::params::compute_service_name,
      ensure_package => $ensure_package,
      before         => Exec['networking-refresh']
    }

    file { 'vcenter-nova-compute-ocf':
      path   => '/usr/lib/ocf/resource.d/mirantis/nova-compute',
      source => 'puppet:///modules/vmware/ocf/nova-compute',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    $vsphere_clusters = split($vcenter_cluster, ",")

    # Create nova-compute per vsphere cluster
    vmware::compute::ha { $vsphere_clusters: }

    Nova::Generic_service['compute']->
    anchor { 'vmware-nova-compute-start': }->
    File['vcenter-nova-compute-ocf']->
    Vmware::Compute::Ha<||>->
    anchor { 'vmware-nova-compute-end': }
  }

  # network configuration
  class { 'vmware::network':
    use_quantum => $use_quantum,
    ha_mode => $ha_mode
  }

  # Enable metadata service on Controller node
  Nova_config <| title == 'DEFAULT/enabled_apis' |> { value => 'ec2,osapi_compute,metadata' }

  # install cirros vmdk package
  package { 'cirros-testvmware':
    ensure => "present"
  }
  package { 'python-suds':
    ensure   => present
  }
}
