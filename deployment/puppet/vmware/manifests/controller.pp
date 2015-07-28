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

# vmware::controller deploys nova-compute service and configures it for use
# with vmwareapi.VCDriver (vCenter server as hypervisor) on OpenStack controller
# nodes.  Nova-compute is configured to work under Pacemaker supervision.
#
# Variables:
# vcenter_settings       -
# vcenter_host_ip        - vCenter server hostname or IP address
# vcenter_user           - username for vCenter server
# vcenter_password       - password for $vcenter_user
# vlan_interface         - VLAN interface on which networks will be provisioned
#                          if VLANManager is used for nova-network
# vnc_address            - IP address on which VNC server will be listening on
# use_quantum            - shows if neutron is enabled

# modules needed: nova
# limitations:
# - only one vcenter supported
class vmware::controller (
  $vcenter_settings = undef,
  $vcenter_host_ip  = '10.10.10.10',
  $vcenter_user     = 'user',
  $vcenter_password = 'password',
  $vlan_interface   = undef,
  $vnc_address      = '0.0.0.0',
  $use_quantum      = false,
)
{
  include nova::params

  # Stubs from nova class in order to not include whole class
  if ! defined(Class['nova']) {
    exec { 'post-nova_config':
      command     => '/bin/echo "Nova config has changed"',
      refreshonly => true,
    }
    exec { 'networking-refresh':
      command     => '/sbin/ifdown -a ; /sbin/ifup -a',
      refreshonly => true,
    }
    package { 'nova-common':
      ensure => 'installed',
      name   => 'binutils',
    }
  }

  package { 'nova-compute':
    ensure => present,
    name   => $::nova::params::compute_package_name,
  }

  if ($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'nova-compute':
      package_name => $::nova::params::compute_package_name,
    }
  }

  service { 'nova-compute':
    ensure => stopped,
    name   => $::nova::params::compute_service_name,
    enable => 'false'
  }

  file { 'vcenter-nova-compute-ocf':
    path   => '/usr/lib/ocf/resource.d/fuel/nova-compute',
    source => 'puppet:///modules/vmware/ocf/nova-compute',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # Create nova-compute per vsphere cluster
  create_resources(vmware::compute::ha, parse_vcenter_settings($vcenter_settings))

  Package['nova-compute']->
  Service['nova-compute']->
  File['vcenter-nova-compute-ocf']->
  Vmware::Compute::Ha<||>->

  class { 'vmware::network':
    use_quantum => $use_quantum,
  }

  # Enable metadata service on Controller node
  # Set correct parameter for vnc access
  nova_config {
    'DEFAULT/enabled_apis':        value => 'ec2,osapi_compute,metadata';
    'DEFAULT/novncproxy_base_url': value => "http://${vnc_address}:6080/vnc_auto.html";
  } -> Service['nova-compute']

  # install cirros vmdk package
  package { 'cirros-testvmware':
    ensure => present
  }
  package { 'python-suds':
    ensure => present
  }
}
