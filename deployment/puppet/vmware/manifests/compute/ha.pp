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
# == Define: vmware::compute::ha
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
#   (required) Name that will form hypervisor name together with
#   'availability_zone_name' in nova-compute.conf.
#
# [*target_node*]
#   (required) Name of node where nova-compute must be deployed. If it matches
#   'current_node' we are deploying nova-compute service.
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
# [*amqp_port*]
#   (optional) The listening port number of the AMQP server. Mandatory to
#   perform a monitor check.
#   Defaults to '5673'.
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
# [*nova_conf*]
#   (required) Path used for nova conf.
#   Defaults to '/etc/nova/nova.conf'.
#
# [*nova_conf_dir*]
#   (optional) The base directory used for compute-vmware configs.
#   Defaults to '/etc/nova/nova-compute.d'.
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
define vmware::compute::ha(
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $target_node,
  $vc_insecure        = true,
  $vc_ca_file         = undef,
  $datastore_regex    = undef,
  $amqp_port          = '5673',
  $api_retry_count    = '5',
  $maximum_objects    = '100',
  $nova_conf          = '/etc/nova/nova.conf',
  $nova_conf_dir      = '/etc/nova/nova-compute.d',
  $task_poll_interval = '5.0',
  $use_linked_clone   = true,
  $wsdl_location      = undef,
) {
  # We deploy nova-compute on controller node only if $target_node contains
  # 'controllers' otherwise service will be deployed on separate node.
  if ($target_node == 'controllers') {
    $nova_compute_conf = "${nova_conf_dir}/vmware-${availability_zone_name}_${service_name}.conf"

    if ! defined(File[$nova_conf_dir]) {
      file { $nova_conf_dir:
        ensure => 'directory',
        owner  => 'nova',
        group  => 'nova',
        mode   => '0750',
      }
    }

    class { '::vmware::ssl::ssl':
        vc_insecure    => $vc_insecure,
        vc_ca_file     => $vc_ca_file,
        vc_ca_filepath => "${nova_conf_dir}/vcenter-${availability_zone_name}_${service_name}-ca.pem",
    }

    $compute_vcenter_ca_filepath   = $::vmware::ssl::ssl::vcenter_ca_filepath
    $compute_vcenter_insecure_real = $::vmware::ssl::ssl::vcenter_insecure_real

    if ! defined(File[$nova_compute_conf]) {
    # $cluster is used inside template
      $cluster = $name
      file { $nova_compute_conf:
        ensure  => 'present',
        content => template('vmware/nova-compute.conf.erb'),
        mode    => '0600',
        owner   => 'nova',
        group   => 'nova',
      }
    }

    $primitive_name = "p_nova_compute_vmware_${availability_zone_name}-${service_name}"

    $primitive_class    = 'ocf'
    $primitive_provider = 'fuel'
    $primitive_type     = 'nova-compute'
    $metadata           = {
      'resource-stickiness' => '1'
    }
    $parameters         = {
      'amqp_server_port'      => $amqp_port,
      'config'                => $nova_conf,
      'pid'                   => "/var/run/nova/nova-compute-${availability_zone_name}-${service_name}.pid",
      'additional_parameters' => "--config-file=${nova_compute_conf}",
    }
    $operations         = {
      'monitor'  => {
        'timeout' => '10',
        'interval' => '20',
      },
      'start'    => {
        'timeout' => '30',
      },
      'stop'     => {
        'timeout' => '30',
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

    File[$nova_conf_dir]->
    Class['::vmware::ssl::ssl']->
    File[$nova_compute_conf]->
    Pcmk_resource[$primitive_name]->
    Service[$primitive_name]
  }
}
