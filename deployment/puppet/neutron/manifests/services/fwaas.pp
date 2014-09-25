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
#
# == Class: neutron::services::fwaas
#
# Configure the Firewall as a Service Neutron Plugin
#
# === Parameters:
#
# [*enabled*]
#   (required) Whether or not to enable the FWaaS neutron plugin Service
#   true/false
#
# [*driver*]
#   (optional) FWaaS Driver to use
#   Defaults to 'neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver'
#
# [*vpnaas_agent_package*]
#   (optional) Use VPNaaS agent package instead of L3 agent package on debian platforms
#   RedHat platforms won't take care of this parameter
#   true/false
#   Defaults to false
#

class neutron::services::fwaas (
  $enabled              = true,
  $driver               = 'neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver',
  $vpnaas_agent_package = false
) {

  include neutron::params

  if ($::osfamily == 'Debian') {
    # Debian platforms
    if $vpnaas_agent_package {
      ensure_resource( 'package', $::neutron::params::vpnaas_agent_package,
        { 'ensure' => $neutron::package_ensure })
      Package[$::neutron::params::vpnaas_agent_package] -> Neutron_fwaas_service_config<||>
    }
    else {
      ensure_resource( 'package', $::neutron::params::l3_agent_package,
        { 'ensure' => $neutron::package_ensure })
      Package[$::neutron::params::l3_agent_package] -> Neutron_fwaas_service_config<||>
    }
  } elsif($::osfamily == 'Redhat') {
    # RH platforms
    ensure_resource( 'package', $::neutron::params::package_name,
      { 'ensure' => $neutron::package_ensure })
    Package[$::neutron::params::package_name] -> Neutron_fwaas_service_config<||>
  }

  neutron_fwaas_service_config {
    'fwaas/enabled': value => $enabled;
    'fwaas/driver':  value => $driver;
  }
}
