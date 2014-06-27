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
# == Class: neutron::agents:metering
#
# Setups Neutron metering agent.
#
# === Parameters
#
# [*package_ensure*]
#   (optional) Ensure state for package. Defaults to 'present'.
#
# [*enabled*]
#   (optional) Enable state for service. Defaults to 'true'.
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*debug*]
#   (optional) Show debugging output in log. Defaults to false.
#
# [*interface_driver*]
#   (optional) Defaults to 'neutron.agent.linux.interface.OVSInterfaceDriver'.
#
# [*use_namespaces*]
#   (optional) Allow overlapping IP (Must have kernel build with
#   CONFIG_NET_NS=y and iproute2 package that supports namespaces).
#   Defaults to true.
#
# [*measure_interval*]
#   (optional) Interval between two metering measures.
#   Defaults to 30.
#
# [*report_interval*]
#   (optional) Interval between two metering reports.
#   Defaults to 300.
#

class neutron::agents::metering (
  $package_ensure   = present,
  $enabled          = true,
  $manage_service   = true,
  $debug            = false,
  $interface_driver = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $use_namespaces   = true,
  $measure_interval = '30',
  $report_interval  = '300'
) {

  include neutron::params

  Neutron_config<||>                ~> Service['neutron-metering-service']
  Neutron_metering_agent_config<||> ~> Service['neutron-metering-service']

  # The metering agent loads both neutron.ini and its own file.
  # This only lists config specific to the agent.  neutron.ini supplies
  # the rest.
  neutron_metering_agent_config {
    'DEFAULT/debug':              value => $debug;
    'DEFAULT/interface_driver':   value => $interface_driver;
    'DEFAULT/use_namespaces':     value => $use_namespaces;
    'DEFAULT/measure_interval':   value => $measure_interval;
    'DEFAULT/report_interval':    value => $report_interval;
  }

  if $::neutron::params::metering_agent_package {
    Package['neutron']            -> Package['neutron-metering-agent']
    Package['neutron-metering-agent'] -> Neutron_config<||>
    Package['neutron-metering-agent'] -> Neutron_metering_agent_config<||>
    package { 'neutron-metering-agent':
      ensure  => $package_ensure,
      name    => $::neutron::params::metering_agent_package,
    }
  } else {
    # Default dependency if the system does not provide a neutron metering agent package.
    Package['neutron'] -> Neutron_metering_agent_config<||>
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'neutron-metering-service':
    ensure  => $service_ensure,
    name    => $::neutron::params::metering_agent_service,
    enable  => $enabled,
    require => Class['neutron'],
  }
}
