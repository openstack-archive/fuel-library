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

# This is the main VMWare integration class
# It should check the variables and basing on them call needed
# subclasses in order to setup VMWare integration with OpenStack

# Variables:
# vcenter_user - contents user name which should be used for configuring
#                integration with vCenter
# vcenter_password - vCenter user password
# vcenter_host_ip - contents IP address of the vCenter host
# vcenter_cluster - contents vCenter cluster name
# vcenter_datastore_regex - the datastore_regex setting specifies the data stores to use with Compute
# vlan_interface - interface which is used on ESXi hosts when nova-network uses VlanManager
# use_quantum - shows if neutron enabled

class vmware (
  $vcenter_settings = undef,
  $vcenter_user     = 'user',
  $vcenter_password = 'password',
  $vcenter_host_ip  = '10.10.10.10',
  $vcenter_cluster  = 'cluster',
  $vlan_interface   = undef,
  $use_quantum      = false,
  $nova_hash        = {},
  $vncproxy_host    = undef,
  $ceilometer       = false,
  $debug            = false,
)
{
  class { 'vmware::controller':
    vcenter_settings  => $vcenter_settings,
    vcenter_user      => $vcenter_user,
    vcenter_password  => $vcenter_password,
    vcenter_host_ip   => $vcenter_host_ip,
    vlan_interface    => $vlan_interface,
    use_quantum       => $use_quantum,
    vncproxy_host     => $vncproxy_host,
    vncproxy_protocol => $nova_hash['vncproxy_protocol'],
    vncproxy_port     => $nova_hash['vncproxy_port'],
  }

  if $ceilometer {
    class { 'vmware::ceilometer':
      vcenter_settings  => $vcenter_settings,
      vcenter_user      => $vcenter_user,
      vcenter_password  => $vcenter_password,
      vcenter_host_ip   => $vcenter_host_ip,
      vcenter_cluster   => $vcenter_cluster,
      debug             => $debug,
    }
  }
}
