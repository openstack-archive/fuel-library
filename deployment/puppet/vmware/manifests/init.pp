#
# Copyright 2016 Mirantis, Inc.
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
# == Class: vmware
#
# This is the main VMware integration class. It should check the variables and
# basing on them call needed subclasses in order to setup VMware integration
# with OpenStack.
#
# === Parameters
#
# [*vcenter_settings*]
#   (required) Computes hash in format of:
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
# [*vcenter_user*]
#   (optional) Username for connection to VMware vCenter host.
#   Defaults to 'user'.
#
# [*vcenter_password*]
#   (optional) Password for connection to VMware vCenter host.
#   Defaults to 'password'.
#
# [*vcenter_host_ip*]
#   (optional) Hostname or IP address for connection to VMware vCenter host.
#   Defaults to '10.10.10.10'.
#
# [*vcenter_cluster*]
#   (optional) Name of a VMware Cluster ComputeResource.
#   Defaults to 'cluster'.
#
# [*vlan_interface*]
#   (optional) Physical ethernet adapter name for vlan networking.
#   Defaults to undef.
#
# [*use_quantum*]
#   (optional) Shows if neutron is enabled.
#   Defaults to false.
#
# [*vncproxy_protocol*]
#   (required) The protocol to communicate with the VNC proxy server.
#   Defaults to 'http'.
#
# [*vncproxy_host*]
#   (required) IP address on which VNC server will be listening on.
#   Defaults to undef.
#
# [*nova_hash*]
#   (required) Nova hash in format of:
#   Example:
#   {"db_password"=>"JC4W0MTwtb6I0f8gBcKjJdiT", "enable_hugepages"=>false,
#    "state_path"=>"/var/lib/nova", "user_password"=>"xT4rEWlhmI4KCyo2pGCMJwsz",
#    "vncproxy_protocol"=>"http", "nova_rate_limits"=> {"POST"=>"100000",
#    "POST_SERVERS"=>"100000", "PUT"=>"1000", "GET"=>"100000",
#    "DELETE"=>"100000"}, "nova_report_interval"=>"60",
#    "nova_service_down_time"=>"180", "num_networks"=>nil, "network_size"=>nil,
#    "network_manager"=>nil}
#   Defaults to {}.
#
# [*ceilometer*]
#   (optional) IP address on which VNC server will be listening on.
#   Defaults to 'false'.
#
# [*debug*]
#   (optional) If set to true, the logging level will be set to DEBUG instead of
#   the default INFO level.
#   Defaults to 'false'.
#
class vmware (
  $vcenter_settings  = undef,
  $vcenter_user      = 'user',
  $vcenter_password  = 'password',
  $vcenter_host_ip   = '10.10.10.10',
  $vcenter_cluster   = 'cluster',
  $vlan_interface    = undef,
  $use_quantum       = false,
  $vncproxy_protocol = 'http',
  $vncproxy_host     = undef,
  $nova_hash         = {},
  $ceilometer        = false,
  $debug             = false,
)
{
  class { '::vmware::controller':
    vcenter_settings  => $vcenter_settings,
    vcenter_user      => $vcenter_user,
    vcenter_password  => $vcenter_password,
    vcenter_host_ip   => $vcenter_host_ip,
    vlan_interface    => $vlan_interface,
    use_quantum       => $use_quantum,
    vncproxy_protocol => $vncproxy_protocol,
    vncproxy_host     => $vncproxy_host,
    vncproxy_port     => $nova_hash['vncproxy_port'],
  }

  if $ceilometer {
    class { '::vmware::ceilometer':
      vcenter_settings => $vcenter_settings,
      vcenter_user     => $vcenter_user,
      vcenter_password => $vcenter_password,
      vcenter_host_ip  => $vcenter_host_ip,
      vcenter_cluster  => $vcenter_cluster,
      debug            => $debug,
    }
  }
}
