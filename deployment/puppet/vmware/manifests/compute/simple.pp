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
  $index,
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
      mode   => '0750'
    }
  }

  $nova_compute_conf = "${nova_conf_dir}/vmware-${index}.conf"

  $nova_compute_vmware = "${::nova::compute_service_name}-vmware"
  case $::osfamily {
    'RedHat': {
      $nova_compute_vmware_init = "/etc/init.d/${nova_compute_vmware}"

      if ! defined(File[$nova_compute_vmware_init]) {
        file { $nova_compute_vmware_init:
          owner  => root,
          group  => root,
          mode   => '0755',
          source => 'puppet:///modules/vmware/nova-compute-init-centos',
        }
      }

      $nova_compute_default = "/etc/sysconfig/${nova_compute_vmware}-${index}"
      if ! defined(File[$nova_compute_default]) {
        file { $nova_compute_default:
          ensure  => present,
          content => "OPTIONS='--config-file=${nova_conf} --config-file=${nova_compute_conf}'",
        }
      }

      $init_link = "${nova_compute_vmware_init}-${index}"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => "${nova_compute_vmware_init}"
        }
      }

      $init_reload_cmd = '/bin/true'
    }
    'Debian': {
      $nova_compute_default = "/etc/default/${nova_compute_vmware}-${index}"
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
          mode   => '0644',
          source => 'puppet:///modules/vmware/nova-compute-init-ubuntu',
        }
      }

      $init_link = "/etc/init/${nova_compute_vmware}-${index}.conf"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => "${nova_compute_vmware_init}"
        }
      }

      $upstart_link = "/etc/init.d/${nova_compute_vmware}-${index}"
      if ! defined(File[$upstart_link]) {
        file { $upstart_link:
          ensure => link,
          target => '/etc/init.d/nova-compute'
        }
      }

      $init_reload_cmd = '/sbin/initctl reload-configuration'
    }
    default: {
      fail { "Unsupported OS family (${::osfamily})": }
    }
  }

  # $cluster is used inside template
  $cluster = $name
  if ! defined (File["${nova_compute_conf}"]) {
    file { "${nova_compute_conf}":
      ensure  => present,
      content => template('vmware/nova-compute.conf.erb'),
      mode    => '0600',
      owner   => nova,
      group   => nova,
    }
  }

  $init_reload = 'initctl reload-configuration'
  if ! defined(Exec[$init_reload]) {
    exec { $init_reload:
      command => "${init_reload_cmd}",
      path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ]
    }
  }

  if ! defined(Service["nova_compute_vmware_${index}"]) {
    service { "nova_compute_vmware_${index}":
      ensure => running,
      name   => "${nova_compute_vmware}-${index}",
      enable => true,
      before => Exec['networking-refresh']
    }
  }

  File[$nova_conf_dir]->
  File[$nova_compute_conf]->
  File[$nova_compute_vmware_init]->
  File[$nova_compute_default]~>
  Exec[$init_reload]->
  Service["nova_compute_vmware_${index}"]
}
