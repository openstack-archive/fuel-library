#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
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
# == Class: neutron::agents::ml2::sriov
#
# Setups SR-IOV neutron agent when using ML2 plugin
#
# === Parameters
#
# [*package_ensure*]
#   (optional) The state of the package
#   Defaults to 'present'
#
# [*enabled*]
#   (required) Whether or not to enable the OVS Agent
#   Defaults to true
#
# [*physical_device_mappings*]
#   (optional) List of <physical_network>:<physical device>
#   All physical networks listed in network_vlan_ranges
#   on the server should have mappings to appropriate
#   interfaces on each agent.
#   Defaults to empty list
#
# [*polling_interval*]
#   (optional) The number of seconds the agent will wait between
#   polling for local device changes.
#   Defaults to '2"
#
# [*exclude_devices*]
#   (optional) List of <network_device>:<excluded_devices> mapping
#   network_device to the agent's node-specific list of virtual functions
#   that should not be used for virtual networking. excluded_devices is a
#   semicolon separated list of virtual functions to exclude from network_device.
#   The network_device in the mapping should appear in the physical_device_mappings list.
class neutron::agents::ml2::sriov (
  $package_ensure             = 'present',
  $enabled                    = true,
  $physical_device_mappings   = [],
  $polling_interval           = 2,
  $exclude_devices            = [],
) {

  include ::neutron::params

  Neutron_plugin_ml2<||> ~> Service['neutron-sriov-nic-agent-service']

  neutron_plugin_ml2 {
    'sriov_nic/polling_interval':         value => $polling_interval;
    'sriov_nic/exclude_devices':          value => join($exclude_devices, ',');
    'sriov_nic/physical_device_mappings': value => join($physical_device_mappings, ',');
  }


  Package['neutron-sriov-nic-agent'] -> Neutron_plugin_ml2<||>
  package { 'neutron-sriov-nic-agent':
    ensure => $package_ensure,
    name   => $::neutron::params::sriov_nic_agent_package,
    tag    => 'openstack',
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'neutron-sriov-nic-agent-service':
    ensure  => $service_ensure,
    name    => $::neutron::params::sriov_nic_agent_service,
    enable  => $enabled,
    require => Class['neutron'],
  }

}
