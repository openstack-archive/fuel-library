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
#
# This type creates nova-compute service for provided vSphere
# cluster (cluster that is formed of ESXi hosts and is managed by vCenter
# server).

define vmware::compute::ha(
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $target_node,
  $datastore_regex = undef,
  $amqp_port = '5673',
  $api_retry_count = '5',
  $maximum_objects = '100',
  $nova_conf = '/etc/nova/nova.conf',
  $nova_conf_dir = '/etc/nova/nova-compute.d',
  $task_poll_interval = '5.0',
  $use_linked_clone = true,
  $wsdl_location = undef
) {
  # We deploy nova-compute on controller node only if
  # $target_node contains 'controllers' otherwise
  # service will be deployed on separate node
  if ($target_node == 'controllers') {
    $nova_compute_conf = "${nova_conf_dir}/vmware-${availability_zone_name}_${service_name}.conf"

    if ! defined(File[$nova_conf_dir]) {
      file { $nova_conf_dir:
        ensure => 'directory',
        owner  => 'nova',
        group  => 'nova',
        mode   => '0750'
      }
    }

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

    pacemaker::new::wrapper { $primitive_name :
      prefix => false,
      primitive_class => $primitive_class,
      primitive_provider => $primitive_provider,
      primitive_type => $primitive_type,
      metadata => $metadata,
      parameters => $parameters,
      operations => $operations,
    }

    service { $primitive_name :
      ensure => 'running',
      enable => true,
    }

    File["${nova_conf_dir}"]->
    File["${nova_compute_conf}"]->
    Pacemaker_resource[$primitive_name]->
    Service[$primitive_name]
  }
}

