#
# Copyright 2016 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Define: vmware::compute_vmware
#
# This resource deploys nova-compute service and configures it for use with
# vmwareapi.VCDriver (vCenter server as hypervisor).
# Depends on nova::params class.
#
# === Parameters
#
# [*availability_zone_name*]
#   (required) Availability zone which nova-compute will be assigned.
#
# [*vc_cluster*]
#   (required) Name of a VMware Cluster ComputeResource.
#
# [*vc_host*]
#   (required) Hostname or IP address for connection to VMware vCenter host.
#
# [*vc_user*]
#   (required) Username for connection to VMware vCenter host.
#
# [*vc_password*]
#   (required) Password for connection to VMware vCenter host.
#
# [*service_name*]
#   (required) Name that will form hypervisor name together with
#   'availability_zone_name' in nova-compute.conf.
#
# [*current_node*]
#   (required) Name of node that we are executing manifest (e.g. 'node-4').
#
# [*target_node*]
#   (required) Name of node where nova-compute must be deployed. If it matches
#   'current_node' we are deploying nova-compute service.
#
# [*vlan_interface*]
#   (optional) Physical ethernet adapter name for vlan networking.
#
# [*vc_insecure*]
#   (optional) If true, the vCenter server certificate is not verified.
#   If false, then the default CA truststore is used for verification. This
#   option is ignored if “ca_file” is set.
#   Defaults to 'True'.
#
# [*vc_ca_file*]
#   (optional) The hash name of the CA bundle file and data in format of:
#   Example:
#   "{"vc_ca_file"=>{"content"=>"RSA", "name"=>"vcenter-ca.pem"}}"
#   Defaults to undef.
#
# [*datastore_regex*]
#   (optional) Regex to match the name of a datastore.
#   Defaults to undef.
#
# [*api_retry_count*]
#   (required) The number of times we retry on failures, e.g.,
#   socket error, etc.
#   Defaults to '5'.
#
# [*maximum_objects*]
#   (required) The maximum number of ObjectContent data objects that should be
#   returned in a single result. A positive value will cause the operation to
#   suspend the retrieval when the count of objects reaches the specified
#   maximum. The server may still limit the count to something less than the
#   configured value. Any remaining objects may be retrieved with additional
#   requests.
#   Defaults to '100'.
#
# [*nova_compute_conf*]
#   (required) Path used for compute-vmware conf.
#   Defaults to '/etc/nova/nova-compute.conf'.
#
# [*task_poll_interval*]
#   (required) The interval used for polling of remote tasks.
#   Defaults to '5.0'.
#
# [*use_linked_clone*]
#   (required) Whether to use linked clone.
#   Defaults to true.
#
# [*wsdl_location*]
#   (optional) Optional VIM Service WSDL Location
#   e.g 'http://<server>/vimService.wsdl'. Optional over-ride to default
#   location for bug workarounds.
#   Defaults to undef.
#
# [*service_enabled*]
#   (optional) Manage nova-compute service.
#   Defaults to false.
#
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
  $vc_insecure        = true,
  $vc_ca_file         = undef,
  $datastore_regex    = undef,
  $api_retry_count    = '5',
  $maximum_objects    = '100',
  $nova_compute_conf  = '/etc/nova/nova-compute.conf',
  $task_poll_interval = '5.0',
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

  # We skip deployment if current node name is not same as target_node.
  if ($target_node == $current_node) {
    class { '::vmware::ssl::ssl':
        vc_insecure    => $vc_insecure,
        vc_ca_file     => $vc_ca_file,
        vc_ca_filepath => '/etc/nova/vcenter-ca.pem',
    }

    $compute_vcenter_ca_filepath   = $::vmware::ssl::ssl::vcenter_ca_filepath
    $compute_vcenter_insecure_real = $::vmware::ssl::ssl::vcenter_insecure_real

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
    Class['::vmware::ssl::ssl']->
    File[$nova_compute_conf]->
    Service['nova-compute']
  }
}
