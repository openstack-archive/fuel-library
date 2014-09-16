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

define vmware::nova_compute_simple(
  $api_retry_count = 5,
  $compute_driver = 'vmwareapi.VMwareVCDriver',
  $maximum_objects = 100,
  $nova_conf = '/etc/nova/nova.conf',
  $task_poll_interval = 5.0,
  $use_linked_clone = true,
  $wsdl_location = undef
)
{
  # We expect that resource name contains vSphere cluster name, e.g. 'Cluster1'
  $nova_compute_conf = "/etc/nova/nova-compute.d/vcenter-${name}.conf"

  if !defined(File['/etc/nova/nova-compute.d']) {
    file { '/etc/nova/nova-compute.d':
      ensure => directory,
      owner  => 'nova',
      group  => 'nova',
      mode   => '0750'
    }
  }

  $nova_compute_vcenter_init = "/etc/init.d/openstack-nova-compute-vcenter"
  if !defined(File[$nova_compute_vcenter_init]) {
    file { $nova_compute_vcenter_init:
      owner  => root,
      group  => root,
      mode   => 0755,
    }
  }

  case $::osfamily {
    'RedHat': {
      File[$nova_compute_vcenter_init] {
        source => 'puppet:///modules/vmware/nova-compute-init-centos',
      }
    }
    'Debian': {
      File[$nova_compute_vcenter_init] {
        source => 'puppet:///modules/vmware/nova-compute-init-ubuntu',
      }
    }
    default: {
      fail { "Unsupported OS family ($::osfamily)": }
    }
  }

  file { "${nova_compute_conf}":
    content => template("vmware/nova-compute.conf.erb"),
    mode    => '0600',
    owner   => 'nova',
    group   => 'nova',
    ensure  => present,
  }

  # Create link named /etc/init.d/openstack-nova-compute-vcenter.ClusterName
  # and link it to /etc/init.d/openstack-nova-compute-vcenter
  # init script splits its own file name and extracts cluster name which is
  # part of file name (after dot character).
  file { "${nova_compute_vcenter_init}.${name}":
    ensure => link,
    target => "${nova_compute_vcenter_init}"
  }

  service { "nova_compute_vcenter_${name}":
    name   => "${::nova::compute_service_name}.${name}",
    ensure => running,
    enable => true,
    before => Exec['networking-refresh']
  }

  File['/etc/nova/nova-compute.d']->
  File[$nova_compute_vcenter_init]->
  File[$nova_compute_conf]->
  Service["nova_compute_vcenter_${name}"]

}
