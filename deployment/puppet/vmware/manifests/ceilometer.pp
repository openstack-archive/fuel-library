# Copyright 2016 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: vmware::ceilometer
#
# Deploys nova-compute service and configures it for use
# with vmwareapi.VCDriver (vCenter server as hypervisor)
# on OpenStack controller nodes. Nova-compute is configured
# to work under Pacemaker supervision.
#
# === Parameters
#
# [*vcenter_settings*]
#   (optional) Computes hash in format of:
#   Example:
#   "[ {"availability_zone_name"=>"vcenter", "datastore_regex"=>".*",
#       "service_name"=>"vm_cluster1", "target_node"=>"controllers",
#       "vc_cluster"=>"Cluster1", "vc_host"=>"172.16.0.254",
#       "vc_password"=>"Qwer!1234", "vc_user"=>"administrator@vsphere.local"},
#      {"availability_zone_name"=>"vcenter", "datastore_regex"=>".*",
#       "service_name"=>"vm_cluster2", "target_node"=>"node-65",
#       "vc_cluster"=>"Cluster2", "vc_host"=>"172.16.0.254",
#       "vc_password"=>"Qwer!1234", "vc_user"=>"administrator@vsphere.local"} ]"
#   Defaults to undef.
#
# [*vcenter_user*]
#   (optional) Username for connection to VMware vCenter host.
#   Defaults to 'user'.
#
# [*vcenter_password*]
#   (optional) Password for connection to VMware vCenter host.
#   Defaults to 'password'.
#
# [*vcenter_host_ip*]
#   (optional) Hostname or IP address for connection to VMware vCenter host.
#   Defaults to '10.10.10.10'.
#
# [*vcenter_cluster*]
#   (optional) Name of a VMware Cluster ComputeResource.
#   Defaults to 'cluster'.
#
# [*hypervisor_inspector*]
#   (optional) Inspector to use for inspecting the hypervisor layer. Known
#   inspectors are libvirt, hyperv, vmware, xenapi and powervm.
#   Defaults to 'vmware'.
#
# [*api_retry_count*]
#   (optional) Number of times a VMware vSphere API may be retried.
#   Defaults to '5'.
#
# [*task_poll_interval*]
#   (optional) Sleep time in seconds for polling an ongoing async task.
#   Defaults to '5.0'.
#
# [*wsdl_location*]
#   (optional) Optional vim service WSDL location
#   e.g http://<server>/vimService.wsdl. Optional over-ride to default location
#   for bug work-arounds.
#   Defaults to false.
#
# [*debug*]
#   (optional) Flag that turn debug logging.
#   Defaults to false.
#
class vmware::ceilometer (
  $vcenter_settings     = undef,
  $vcenter_user         = 'user',
  $vcenter_password     = 'password',
  $vcenter_host_ip      = '10.10.10.10',
  $vcenter_cluster      = 'cluster',
  $hypervisor_inspector = 'vmware',
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

  include ::ceilometer::params

  package { 'ceilometer-agent-compute':
    ensure => present,
    name   => $::ceilometer::params::agent_compute_package_name,
  }

  create_resources(vmware::ceilometer::ha, parse_vcenter_settings($vcenter_settings))

  Package['ceilometer-agent-compute']->
  Vmware::Ceilometer::Ha<||>
}
