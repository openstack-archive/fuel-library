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
#
# neutron::plugins::ml2::type_driver used by neutron::plugins::ml2
#

define neutron::plugins::ml2::type_driver (
  $flat_networks,
  $tunnel_id_ranges,
  $network_vlan_ranges,
  $vni_ranges,
  $vxlan_group
){
  if ($name == 'flat') {
    neutron_plugin_ml2 {
      'ml2_type_flat/flat_networks': value => join($flat_networks, ',');
    }
  }
  elsif ($name == 'gre') {
    # tunnel_id_ranges is required in gre
    if ! $tunnel_id_ranges {
      fail('when gre is part of type_drivers, tunnel_id_ranges should be given.')
    }

    validate_tunnel_id_ranges($tunnel_id_ranges)

    neutron_plugin_ml2 {
      'ml2_type_gre/tunnel_id_ranges': value => join($tunnel_id_ranges, ',');
    }
  }
  elsif ($name == 'vlan') {
    # network_vlan_ranges is required in vlan
    if ! $network_vlan_ranges {
      fail('when vlan is part of type_drivers, network_vlan_ranges should be given.')
    }

    validate_network_vlan_ranges($network_vlan_ranges)

    neutron_plugin_ml2 {
      'ml2_type_vlan/network_vlan_ranges': value => join($network_vlan_ranges, ',');
    }
  }
  elsif ($name == 'vxlan') {
    # vni_ranges and vxlan_group are required in vxlan
    if (! $vni_ranges) or (! $vxlan_group) {
      fail('when vxlan is part of type_drivers, vni_ranges and vxlan_group should be given.')
    }
    # test multicast ip address (ipv4 else ipv6):
    case $vxlan_group {
      /^2[\d.]+$/: {
        case $vxlan_group {
          /^(22[4-9]|23[0-9])\.(\d+)\.(\d+)\.(\d+)$/: { }
          default: { }
        }
      }
      /^ff[\d.]+$/: { }
      default: {
        fail("${vxlan_group} is not valid for vxlan_group.")
      }
    }

    validate_vni_ranges($vni_ranges)

    neutron_plugin_ml2 {
      'ml2_type_vxlan/vxlan_group': value => $vxlan_group;
      'ml2_type_vxlan/vni_ranges':  value => join($vni_ranges, ',');
    }
  }
  elsif ($name == 'local') {
    warning('local type_driver is useful only for single-box, because it provides no connectivity between hosts')
  }
  else {
    # detect an invalid type_drivers value
    fail('type_driver unknown.')
  }
}
