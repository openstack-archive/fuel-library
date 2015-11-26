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
# nodes. Nova-compute is configured to work under Pacemaker supervision.
#
# Variables:
# vcenter_settings       -
# vcenter_host_ip        - vCenter server hostname or IP address
# vcenter_user           - username for vCenter server
# vcenter_password       - password for $vcenter_user
# vlan_interface         - VLAN interface on which networks will be provisioned
#                          if VLANManager is used for nova-network
# vncproxy_host          - IP address on which VNC server will be listening on
# vncproxy_protocol      - the protocol to communicate with the VNC proxy server
# vncproxy_port          - the port to communicate with the VNC proxy server
# vncproxy_path          - the path at the end of the uri for communication
#                          with the VNC proxy server
# use_quantum            - shows if neutron is enabled

# modules needed: nova
# limitations:
# - only one vcenter supported
class vmware::controller (
  $vcenter_settings  = undef,
  $vcenter_host_ip   = '10.10.10.10',
  $vcenter_user      = 'user',
  $vcenter_password  = 'password',
  $vlan_interface    = undef,
  $vncproxy_host     = false,
  $vncproxy_protocol = 'http',
  $vncproxy_port     = '6080',
  $vncproxy_path     = '/vnc_auto.html',
  $use_quantum       = false,
)
{
  include nova::params
  $vncproxy_base_url = "${vncproxy_protocol}://${vncproxy_host}:${vncproxy_port}${vncproxy_path}"

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
      ensure  => 'installed',
      name    => 'binutils',
    }
  }

  $libvirt_type = hiera('libvirt_type')
  tweaks::ubuntu_service_override { 'nova-compute':
    package_name => "nova-compute-${libvirt_type}",
  }

  package { 'nova-compute':
    ensure => 'present',
    name   => $::nova::params::compute_package_name,
  }

  service { 'nova-compute':
    name   => $::nova::params::compute_service_name,
    ensure => 'stopped',
    enable => false
  }

  # Create nova-compute per vsphere cluster
  create_resources(vmware::compute::ha, parse_vcenter_settings($vcenter_settings))

  Package['nova-compute']->
  Service['nova-compute']->
  Vmware::Compute::Ha<||>->

  class { 'vmware::network':
    use_quantum => $use_quantum,
  }

  # Enable metadata service on Controller node
  # Set correct parameter for vnc access
  nova_config {
    'DEFAULT/enabled_apis':        value => 'ec2,osapi_compute,metadata';
    'DEFAULT/novncproxy_base_url': value => $vncproxy_base_url;
  } -> Service['nova-compute']

  # install cirros vmdk package
  package { 'cirros-testvmware':
    ensure => present
  }
  package { 'python-suds':
    ensure => present
  }
}
