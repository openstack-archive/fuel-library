#
# Copyright (C) 2014 Mirantis
#
# Author: Steapn Rogov <srogov@mirantis.com>
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
# == Class: glance::backend::vsphere
#
# Setup Glance to backend images into VMWare vCenter/ESXi
#
# === Parameters
#
# [*vcenter_api_insecure*]
#   (optional) Allow to perform insecure SSL requests to vCenter/ESXi.
#   Should be a valid string boolean value
#   Defaults to 'False'
#
# [*vcenter_host*]
#   (required) vCenter/ESXi Server target system.
#   Should be a valid an IP address or a DNS name.
#
# [*vcenter_user*]
#   (required) Username for authenticating with vCenter/ESXi server.
#
# [*vcenter_password*]
#   (required) Password for authenticating with vCenter/ESXi server.
#
# [*vcenter_datacenter*]
#   (required) Inventory path to a datacenter.
#   If you want to use ESXi host as datastore,it should be "ha-datacenter".
#
# [*vcenter_datastore*]
#   (required) Datastore associated with the datacenter.
#
# [*vcenter_image_dir*]
#   (required) The name of the directory where the glance images will be stored
#   in the VMware datastore.
#
# [*vcenter_task_poll_interval*]
#   (optional) The interval used for polling remote tasks invoked on
#   vCenter/ESXi server.
#   Defaults to '5'
#
# [*vcenter_api_retry_count*]
#   (optional) Number of times VMware ESX/VC server API must be retried upon
#   connection related issues.
#    Defaults to '10'
#
class glance::backend::vsphere(
  $vcenter_host,
  $vcenter_user,
  $vcenter_password,
  $vcenter_datacenter,
  $vcenter_datastore,
  $vcenter_image_dir,
  $vcenter_api_insecure = 'False',
  $vcenter_task_poll_interval = '5',
  $vcenter_api_retry_count = '10',
) {
  glance_api_config {
    'DEFAULT/default_store': value             => 'vsphere';
    'DEFAULT/vmware_api_insecure': value       => $vcenter_api_insecure;
    'DEFAULT/vmware_server_host': value        => $vcenter_host;
    'DEFAULT/vmware_server_username': value    => $vcenter_user;
    'DEFAULT/vmware_server_password': value    => $vcenter_password;
    'DEFAULT/vmware_datastore_name': value     => $vcenter_datastore;
    'DEFAULT/vmware_store_image_dir': value    => $vcenter_image_dir;
    'DEFAULT/vmware_task_poll_interval': value => $vcenter_task_poll_interval;
    'DEFAULT/vmware_api_retry_count': value    => $vcenter_api_retry_count;
    'DEFAULT/vmware_datacenter_path': value    => $vcenter_datacenter;
  }
}
