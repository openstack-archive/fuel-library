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
# It should check the variables and basing on them call needed subclasses in order to setup VMWare integration with OpenStack
# Variables:
# vcenter_user - contents user name which should be used for configuring integration with vCenter
# vcenter_password - vCenter user password
# vcenter_host_ip - contents IP address of the vCenter host
# vcenter_cluster - contents vCenter cluster name (multi-cluster is not supported yet)
# use_quantum - shows if neutron enabled

class vmware (

  $vcenter_user = 'user',
  $vcenter_password = 'password',
  $vcenter_host_ip = '10.10.10.10',
  $vcenter_cluster = 'cluster',
  $use_quantum = false,
  $ha_mode = false,
)

{ # begin of class

  class { 'vmware::controller':
    vcenter_user => $vcenter_user,
    vcenter_password => $vcenter_password,
    vcenter_host_ip => $vcenter_host_ip,
    vcenter_cluster => $vcenter_cluster,
    use_quantum => $use_quantum,
    ha_mode => $ha_mode,
  }

} # end of class
