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
# - only one vmware cluster supported

class vmware::controller (

  $vcenter_user = 'user',
  $vcenter_password = 'password',
  $vcenter_host_ip = '10.10.10.10',
  $vcenter_cluster = 'cluster',
  $use_quantum = false,
  $ensure_package = 'present',
  $ha_mode = false,
  $amqp_port = '5673',
  $nova_compute_config = '/etc/nova/nova.conf',
  $nova_compute_vmware_config = '/etc/nova/nova-compute.conf',
  $api_retry_count = 5,
  $maximum_objects = 100,
  $task_poll_interval = 5.0,
  $use_linked_clone = true,
  $wsdl_location = undef,
  $compute_driver = 'vmwareapi.VMwareVCDriver',
)

{ # begin of class

  if ! $ha_mode {
    # installing the nova-compute service
    nova::generic_service { 'compute':
      enabled        => true,
      package_name   => $::nova::params::compute_package_name,
      service_name   => $::nova::params::compute_service_name,
      ensure_package => $ensure_package,
      before         => Exec['networking-refresh']
    }
  } else {
    nova::generic_service { 'compute':
      enabled        => false,
      package_name   => $::nova::params::compute_package_name,
      service_name   => $::nova::params::compute_service_name,
      ensure_package => $ensure_package,
      before         => Exec['networking-refresh']
    }

    cs_resource { 'p_vcenter_nova_compute':
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'nova-compute',
      metadata        => {
        'resource-stickiness' => '1'
      },
      parameters      => {
        'amqp_server_port' => $amqp_port,
        'config' => $nova_compute_config,
        'additional_parameters' => "--config-file=${nova_compute_vmware_config}",
      },
      operations      => {
        'monitor'  => {
          'interval' => '20',
          'timeout'  => '10',
        },
          'start'  => {
          'timeout' => '30',
        },
          'stop'   => {
          'timeout' => '30',
        }
      }
    }

    file { 'vcenter-nova-compute-ocf':
      path  => '/usr/lib/ocf/resource.d/mirantis/nova-compute',
      source => 'puppet:///modules/vmware/ocf/nova-compute',
      owner => 'root',
      group => 'root',
      mode => '0755',
    }

    service { 'p_vcenter_nova_compute':
      ensure => 'running',
      enable => true,
      provider => 'pacemaker',
    }

    anchor { 'vcenter-nova-compute-start': }
    anchor { 'vcenter-nova-compute-end': }

    Anchor <| title == 'nailgun::rabbitmq end' |>->
    Anchor['vcenter-nova-compute-start']

    Anchor['vcenter-nova-compute-start']->
    Nova::Generic_service['compute']->
    File['/etc/nova/nova-compute.conf']->
    File['vcenter-nova-compute-ocf']->
    Cs_resource['p_vcenter_nova_compute']->
    Service['p_vcenter_nova_compute']->
    Anchor['vcenter-nova-compute-end']

  }


  # network configuration
  class { 'vmware::network':
    use_quantum => $use_quantum,
    ha_mode => $ha_mode
  }
  file { "/etc/nova/nova-compute.conf":
    content => template ("vmware/nova-compute.conf.erb"),
    mode => 0644,
    owner => root,
    group => root,
    ensure => present,
  }
  # workaround for Ubuntu additional package for hypervisor
  case $::osfamily { # open case
    'RedHat': { # open RedHat
      # nova-compute service configuration
      file { '/etc/sysconfig/openstack-nova-compute':
        ensure => present,
      } ->
      file_line { 'nova-compute env':
        path => '/etc/sysconfig/openstack-nova-compute',
        line => "OPTIONS='--config-file=/etc/nova/nova.conf --config-file=/etc/nova/nova-compute.conf'",
      }
    } # close RedHat
  } # close case

  # install cirros vmdk package

  package { 'cirros-testvmware':
    ensure => "present"
  }
  package { 'python-suds':
    ensure   => present
  }

} # end of class
