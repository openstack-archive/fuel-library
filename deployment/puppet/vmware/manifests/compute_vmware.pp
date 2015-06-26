#    Copyright 2015 Mirantis, Inc.
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

define vmware::compute_vmware(
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $current_node,
  $target_node,
  $datastore_regex = undef,
  $api_retry_count = 5,
  $maximum_objects = 100,
  $nova_compute_conf = '/etc/nova/nova-compute.conf',
  $task_poll_interval = 5.0,
  $use_linked_clone = true,
  $wsdl_location = undef
)
{
  include nova::params

  # We skip deployment if current node name is not same as target_node
  if ($target_node == $current_node) {
    # $cluster is used inside template
    $cluster = $name
    file { $nova_compute_conf:
      ensure  => present,
      content => template('vmware/nova-compute.conf.erb'),
      mode    => '0600',
      owner   => nova,
      group   => nova,
    }

    package { 'nova-compute':
      ensure => installed,
      name => $::nova::params::compute_package_name,
    }

    nova_config {
      'DEFAULT/host':         value => "$availability_zone_name-$service_name";
      'vmware/cluster_name':  value => $vc_cluster;
      'vmware/host_ip':       value => $vc_host;
      'vmware/host_username': value => $vc_user;
      'vmware/host_password': value => $vc_password;
    }

    service { 'nova-compute':
      name   => $::nova::params::compute_service_name,
      ensure => running,
      enable => true,
    }

    Package['nova-compute']->
    File[$nova_compute_conf]->
    Nova_config<| |>->
    Service['nova-compute']
  }
}
