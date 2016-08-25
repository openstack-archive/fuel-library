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
# == Define: vmware::ceilometer::ha
#
# This type creates nova-compute service for provided vSphere cluster
# (cluster that is formed of ESXi hosts and is managed by vCenter server).
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
#   (required) Parameter to form 'host' parameter.
#
# [*target_node*]
#   (required) Parameter that specifies on which node service will be placed.
#
# [*default_log_levels*]
#   (required) List of package logging levels in logger=LEVEL pairs. This option
#   is ignored if log_config_append is set.
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
# [*vc_insecure*]
#   (optional) If true, the vCenter server certificate is not verified.
#   If false, then the default CA truststore is used for verification. This
#   option is ignored if "ca_file" is set.
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
# [*amqp_port*]
#   (optional) The listening port number of the AMQP server. Mandatory to
#   perform a monitor check.
#   Defaults to '5673'.
#
# [*ceilometer_config*]
#   (required) Path used for ceilometer conf.
#   Defaults to '/etc/ceilometer/ceilometer.conf'.
#
# [*ceilometer_conf_dir*]
#   (optional) The base directory used for ceilometer configs.
#   Defaults to '/etc/ceilometer/ceilometer-compute.d'.
#
define vmware::ceilometer::ha (
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $target_node,
  $default_log_levels,
  $hypervisor_inspector = 'vmware',
  $api_retry_count      = '5',
  $task_poll_interval   = '5.0',
  $vc_insecure          = true,
  $vc_ca_file           = undef,
  $datastore_regex      = undef,
  $amqp_port            = '5673',
  $ceilometer_config    = '/etc/ceilometer/ceilometer.conf',
  $ceilometer_conf_dir  = '/etc/ceilometer/ceilometer-compute.d',
) {
  if ($target_node == 'controllers') {
    $ceilometer_compute_conf = "${ceilometer_conf_dir}/vmware-${availability_zone_name}_${service_name}.conf"
    $vcenter_ca_file         = pick($vc_ca_file, {})
    $vcenter_ca_content      = pick($vcenter_ca_file['content'], {})
    $vcenter_ca_filepath     = "${ceilometer_conf_dir}/vmware-${availability_zone_name}_${service_name}-ca.pem"

    if ! defined(File[$ceilometer_conf_dir]) {
      file { $ceilometer_conf_dir:
        ensure => directory,
        owner  => 'ceilometer',
        group  => 'ceilometer',
        mode   => '0750',
      }
    }

    if ! empty($vcenter_ca_content) and ! $vc_insecure {
      $ceilometer_vcenter_ca_filepath   = $vcenter_ca_filepath
      $ceilometer_vcenter_insecure_real = false

      file { $vcenter_ca_filepath:
        ensure  => file,
        content => $vcenter_ca_content,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
      }
    } else {
      $ceilometer_vcenter_ca_filepath   = $::os_service_default
      $ceilometer_vcenter_insecure_real = $vc_insecure
    }

    if ! defined(File[$ceilometer_compute_conf]) {
      file { $ceilometer_compute_conf:
        ensure  => present,
        content => template('vmware/ceilometer-compute.conf.erb'),
        mode    => '0600',
        owner   => 'ceilometer',
        group   => 'ceilometer',
      }
    }

    $primitive_name = "p_ceilometer_agent_compute_vmware_${availability_zone_name}_${service_name}"

    $primitive_class    = 'ocf'
    $primitive_provider = 'fuel'
    $primitive_type     = 'ceilometer-agent-compute'
    $metadata           = {
      'target-role' => 'stopped',
      'resource-stickiness' => '1'
    }
    $parameters         = {
      'amqp_server_port'      => $amqp_port,
      'config'                => $ceilometer_config,
      'pid'                   => "/var/run/ceilometer/ceilometer-agent-compute-${availability_zone_name}_${service_name}.pid",
      'user'                  => 'ceilometer',
      'additional_parameters' => "--config-file=${ceilometer_compute_conf}",
    }
    $operations         = {
      'monitor'  => {
        'timeout'  => '20',
        'interval' => '30',
      },
      'start'    => {
        'timeout' => '360',
      },
      'stop'     => {
        'timeout' => '360',
      }
    }

    pacemaker::service { $primitive_name :
      prefix             => false,
      primitive_class    => $primitive_class,
      primitive_provider => $primitive_provider,
      primitive_type     => $primitive_type,
      metadata           => $metadata,
      parameters         => $parameters,
      operations         => $operations,
    }

    service { $primitive_name :
      ensure => 'running',
      enable => true,
    }

    File[$ceilometer_conf_dir]->
    File[$ceilometer_compute_conf]->
    Pcmk_resource[$primitive_name]->
    Service[$primitive_name]
  }

}
