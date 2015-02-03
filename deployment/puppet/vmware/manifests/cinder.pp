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

class vmware::cinder(
  $vmware_host_ip       = "1.2.3.4",
  $vmware_host_username = "us@er.name",
  $vmware_host_password = "123",
  $vmware_clusters      = "Cl,str,lst"
)
{
  include cinder
  $vsphere_clusters = vmware_index($vmware_cluster)
  create_resources(vmware::cinder::vmdk, $vsphere_clusters)

  cinder::тратата_service( 'volume':
    .....
  )
  Cinder::..._service['volume']-> Vmware::Cinder<| |>
}
