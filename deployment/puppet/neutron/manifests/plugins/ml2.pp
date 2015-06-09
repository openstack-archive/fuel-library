#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
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

# Configure the neutron server to use the ML2 plugin.
# This configures the plugin for the API server, but does nothing
# about configuring the agents that must also run and share a config
# file with the OVS plugin if both are on the same machine.
#
# === Parameters
#
# [*type_drivers*]
#   (optional) List of network type driver entrypoints to be loaded
#   from the neutron.ml2.type_drivers namespace.
#   Could be an array that can have these elements:
#   local, flat, vlan, gre, vxlan
#   Defaults to ['local', 'flat', 'vlan', 'gre', 'vxlan'].
#
# [*tenant_network_types*]
#   (optional) Ordered list of network_types to allocate as tenant networks.
#   The value 'local' is only useful for single-box testing
#   but provides no connectivity between hosts.
#   Should be an array that can have these elements:
#   local, flat, vlan, gre, vxlan
#   Defaults to ['local', 'flat', 'vlan', 'gre', 'vxlan'].
#
# [*mechanism_drivers*]
#   (optional) An ordered list of networking mechanism driver
#   entrypoints to be loaded from the neutron.ml2.mechanism_drivers namespace.
#   Should be an array that can have these elements:
#   logger, test, linuxbridge, openvswitch, hyperv, ncs, arista, cisco_nexus,
#   l2population.
#   Default to ['openvswitch', 'linuxbridge'].
#
# [*flat_networks*]
#   (optional) List of physical_network names with which flat networks
#   can be created. Use * to allow flat networks with arbitrary
#   physical_network names.
#   Should be an array.
#   Default to *.
#
# [*network_vlan_ranges*]
#   (optional) List of <physical_network>:<vlan_min>:<vlan_max> or
#   <physical_network> specifying physical_network names
#   usable for VLAN provider and tenant networks, as
#   well as ranges of VLAN tags on each available for
#   allocation to tenant networks.
#   Should be an array with vlan_min = 1 & vlan_max = 4094 (IEEE 802.1Q)
#   Default to empty.
#
# [*tunnel_id_ranges*]
#   (optional) Comma-separated list of <tun_min>:<tun_max> tuples
#   enumerating ranges of GRE tunnel IDs that are
#   available for tenant network allocation
#   Should be an array with tun_max +1 - tun_min > 1000000
#   Default to empty.
#
# [*vxlan_group*]
#   (optional) Multicast group for VXLAN.
#   Multicast group for VXLAN. If unset, disables VXLAN enable sending allocate
#   broadcast traffic to this multicast group. When left unconfigured, will
#   disable multicast VXLAN mode
#   Should be an Multicast IP (v4 or v6) address.
#   Default to 'None'.
#
# [*vni_ranges*]
#   (optional) Comma-separated list of <vni_min>:<vni_max> tuples
#   enumerating ranges of VXLAN VNI IDs that are
#   available for tenant network allocation.
#   Min value is 0 and Max value is 16777215.
#   Default to empty.
#
# [*enable_security_group*]
#   (optional) Controls if neutron security group is enabled or not.
#   It should be false when you use nova security group.
#   Defaults to true.
#

class neutron::plugins::ml2 (
  $type_drivers          = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $tenant_network_types  = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $mechanism_drivers     = ['openvswitch', 'linuxbridge'],
  $flat_networks         = ['*'],
  $network_vlan_ranges   = ['physnet1:1000:2999'],
  $tunnel_id_ranges      = ['20:100'],
  $vxlan_group           = '224.0.0.1',
  $vni_ranges            = ['10:100'],
  $enable_security_group = true,
  $package_ensure        = 'present'
) {

  include neutron::params

  Neutron_plugin_ml2<||> ~> Service<| title == 'neutron-server' |>

  validate_array($mechanism_drivers)
  if ! $mechanism_drivers {
    warning('Without networking mechanism driver, ml2 will not communicate with L2 agents')
  }

  if $::operatingsystem == 'Ubuntu' {
    file_line { '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG':
      path    => '/etc/default/neutron-server',
      match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
      line    => 'NEUTRON_PLUGIN_CONFIG=/etc/neutron/plugin.ini',
      require => File['/etc/neutron/plugin.ini'],
    }
    File_line['/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG']
    ~> Service<| title == 'neutron-server' |>
  }

  # In RH, the link is used to start Neutron process but in Debian, it's used only
  # to manage database synchronization.
  file {'/etc/neutron/plugin.ini':
    ensure  => link,
    target  => '/etc/neutron/plugins/ml2/ml2_conf.ini'
  }

  # Some platforms do not have a dedicated ml2 plugin package
  if $::neutron::params::ml2_server_package {
    package { 'neutron-plugin-ml2':
      ensure => $package_ensure,
      name   => $::neutron::params::ml2_server_package,
    }
    Package['neutron-plugin-ml2'] -> Neutron_plugin_ml2<||>
    Package['neutron-plugin-ml2'] -> File['/etc/neutron/plugin.ini']
  } else {
    Package <| title == 'neutron-server' |> -> Neutron_plugin_ml2<||>
    Package['neutron'] -> File['/etc/neutron/plugin.ini']
  }

  neutron::plugins::ml2::driver { $type_drivers:
    flat_networks       => $flat_networks,
    tunnel_id_ranges    => $tunnel_id_ranges,
    network_vlan_ranges => $network_vlan_ranges,
    vni_ranges          => $vni_ranges,
    vxlan_group         => $vxlan_group,
  }

  neutron_plugin_ml2 {
    'ml2/type_drivers':                     value => join($type_drivers, ',');
    'ml2/tenant_network_types':             value => join($tenant_network_types, ',');
    'ml2/mechanism_drivers':                value => join($mechanism_drivers, ',');
    'securitygroup/enable_security_group':  value => $enable_security_group;
  }
}
