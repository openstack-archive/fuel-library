# Copyright 2016 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: vmware::controller
#
# Deploys nova-compute service and configures it for use
# with vmwareapi.VCDriver (vCenter server as hypervisor)
# on OpenStack controller nodes. Nova-compute is configured
# to work under Pacemaker supervision.
#
# === Parameters
#
# [*vcenter_settings*]
#   (optional) Computes hash in format of:
#   Example:
#   "[ {"availability_zone_name"=>"vcenter", "datastore_regex"=>".*",
#       "service_name"=>"vm_cluster1", "target_node"=>"controllers",
#       "vc_cluster"=>"Cluster1", "vc_host"=>"172.16.0.254",
#       "vc_password"=>"Qwer!1234", "vc_user"=>"administrator@vsphere.local"},
#      {"availability_zone_name"=>"vcenter", "datastore_regex"=>".*",
#       "service_name"=>"vm_cluster2", "target_node"=>"node-65",
#       "vc_cluster"=>"Cluster2", "vc_host"=>"172.16.0.254",
#       "vc_password"=>"Qwer!1234", "vc_user"=>"administrator@vsphere.local"} ]"
#   Defaults to undef.
#
# [*vcenter_host_ip*]
#   (optional) Hostname or IP address for connection to VMware vCenter host.
#   Defaults to '10.10.10.10'.
#
# [*vcenter_user*]
#   (optional) Username for connection to VMware vCenter host.
#   Defaults to 'user'.
#
# [*vcenter_password*]
#   (optional) Password for connection to VMware vCenter host.
#   Defaults to 'password'.
#
# [*vlan_interface*]
#   (optional) Physical ethernet adapter name for vlan networking.
#   Defaults to undef.
#
# [*vncproxy_host*]
#   (optional) IP address on which VNC server will be listening on.
#   Defaults to undef.
#
# [*vncproxy_protocol*]
#   (required) The protocol to communicate with the VNC proxy server.
#   Defaults to 'http'.
#
# [*vncproxy_port*]
#   (optional) The port to communicate with the VNC proxy server.
#   Defaults to '6080'.
#
# [*vncproxy_path*]
#   (optional) The path at the end of the uri for communication
#   with the VNC proxy server.
#   Defaults to '/vnc_auto.html'.
#
# [*use_quantum*]
#   (optional) Shows if neutron is enabled.
#   Defaults to false.
#
# Modules needed:
#   nova
#
# Limitations:
#   Only one vCenter supported.
#
class vmware::controller (
  $vcenter_settings  = undef,
  $vcenter_host_ip   = '10.10.10.10',
  $vcenter_user      = 'user',
  $vcenter_password  = 'password',
  $vlan_interface    = undef,
  $vncproxy_host     = undef,
  $vncproxy_protocol = 'http',
  $vncproxy_port     = '6080',
  $vncproxy_path     = '/vnc_auto.html',
  $use_quantum       = false,
)
{
  include ::nova::params
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
      ensure => 'installed',
      name   => 'binutils',
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
    ensure => 'stopped',
    name   => $::nova::params::compute_service_name,
    enable => false,
  }

  # Create nova-compute per vSphere cluster.
  create_resources(vmware::compute::ha, parse_vcenter_settings($vcenter_settings))

  Package['nova-compute']->
  Service['nova-compute']->
  Vmware::Compute::Ha<||>->

  class { '::vmware::network':
    use_quantum => $use_quantum,
  }

  # Enable metadata service on Controller node.
  # Set correct parameter for vnc access.
  nova_config {
    'DEFAULT/enabled_apis':    value => 'ec2,osapi_compute,metadata';
    'vnc/novncproxy_base_url': value => $vncproxy_base_url;
  } -> Service['nova-compute']

  # Install cirros vmdk package.
  package { 'cirros-testvmware':
    ensure => present,
  }
  package { 'python-suds':
    ensure => present,
  }
}
