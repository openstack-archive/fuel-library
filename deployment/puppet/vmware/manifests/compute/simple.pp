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

define vmware::compute::simple(
  $api_retry_count = 5,
  $compute_driver = 'vmwareapi.VMwareVCDriver',
  $maximum_objects = 100,
  $nova_conf = '/etc/nova/nova.conf',
  $nova_conf_dir = '/etc/nova/nova-compute.d',
  $task_poll_interval = 5.0,
  $use_linked_clone = true,
  $wsdl_location = undef
)
{
  include $::nova::params

  if ! defined(File["${nova_conf_dir}"]) {
    file { $nova_conf_dir:
      ensure => directory,
      owner  => nova,
      group  => nova,
      mode   => 0750
    }
  }

  # We expect that resource name contains vSphere cluster name, e.g. 'Cluster1'
  $cluster = $name
  $nova_compute_conf = "${nova_conf_dir}/vmware-${cluster}.conf"

  $nova_compute_vmware = "${::nova::compute_service_name}-vmware"
  case $::osfamily {
    'RedHat': {
      $nova_compute_vmware_init = "/etc/init.d/${nova_compute_vmware}"

      if ! defined(File[$nova_compute_vmware_init]) {
        file { $nova_compute_vmware_init:
          owner  => root,
          group  => root,
          mode   => 0755,
          source => 'puppet:///modules/vmware/nova-compute-init-centos',
        }
      }

      $nova_compute_default = "/etc/sysconfig/${nova_compute_vmware}-${cluster}"
      if ! defined(File[$nova_compute_default]) {
        file { $nova_compute_default:
          ensure  => present,
          content => "OPTIONS='--config-file=${nova_conf} --config-file=${nova_compute_conf}'",
        }
      }

      $init_link = "${nova_compute_vmware_init}-${cluster}"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => "${nova_compute_vmware_init}"
        }
      }
    }
    'Debian': {
      $nova_compute_default = "/etc/default/${nova_compute_vmware}-${cluster}"
      if ! defined(File[$nova_compute_default]) {
        file { $nova_compute_default:
          ensure  => present,
          content => "NOVA_COMPUTE_OPTS='--config-file=${nova_conf} --config-file=${nova_compute_conf}'",
        }
      }

      $nova_compute_vmware_init = "/etc/init/${nova_compute_vmware}.conf"
      if ! defined(File[$nova_compute_vmware_init]) {
        file { $nova_compute_vmware_init:
          owner  => root,
          group  => root,
          mode   => 0644,
          source => 'puppet:///modules/vmware/nova-compute-init-ubuntu',
        }
      }

      $init_link = "/etc/init/${nova_compute_vmware}-${cluster}.conf"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => "${nova_compute_vmware_init}"
        }
      }

      $upstart_link = "/etc/init.d/${nova_compute_vmware}-${cluster}"
      if ! defined(File[$upstart_link]) {
        file { $upstart_link:
          ensure => link,
          target => "/etc/init.d/nova-compute"
        }
      }

      if ! defined(Exec["initctl reload-configuration ${cluster}"]) {
        exec { "initctl reload-configuration ${cluster}":
          command => '/sbin/initctl reload-configuration',
          path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ]
        }
      }
    }
    default: {
      fail { "Unsupported OS family ($::osfamily)": }
    }
  }

  file { "${nova_compute_conf}":
    content => template("vmware/nova-compute.conf.erb"),
    mode    => 0600,
    owner   => nova,
    group   => nova,
    ensure  => present,
  }

  service { "nova_compute_vmware_${cluster}":
    name   => "${nova_compute_vmware}-${cluster}",
    ensure => running,
    enable => true,
    before => Exec['networking-refresh']
  }

  File[$nova_conf_dir]->
  File[$nova_compute_conf]->
  File[$nova_compute_vmware_init]->
  File[$nova_compute_default]->
  Exec<| title == "initctl reload-configuration ${cluster}" |>->
  Service["nova_compute_vmware_${cluster}"]
}
