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
# neutron::plugins::ml2::mech_driver used by neutron::plugins::ml2
#

define neutron::plugins::ml2::mech_driver (
  $supported_pci_vendor_devs,
  $sriov_agent_required,
){
  if ($name == 'sriovnicswitch') {
    neutron_plugin_ml2 {
      'ml2_sriov/supported_pci_vendor_dev': value => join($supported_pci_vendor_devs, ',');
      'ml2_sriov/agent_required':           value => $sriov_agent_required;
    }
  }
}
