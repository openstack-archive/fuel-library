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
# == Class: ceilometer::agent::notification
#
# Configure the ceilometer notification agent.
# This configures the plugin for the API server, but does nothing
# about configuring the agents that must also run and share a config
# file with the OVS plugin if both are on the same machine.
#
# === Parameters
#
# [*enabled*]
#   (optional) Should the service be started or not
#   Defaults to true
#
# [*ack_on_event_error*]
#   (optional) Acknowledge message when event persistence fails.
#   Defaults to true
#
# [*store_events*]
#   (optional) Save event details.
#   Defaults to false
#

class ceilometer::agent::notification (
  $enabled            = true,
  $ack_on_event_error = true,
  $store_events       = false
) {

  include ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-agent-notification']

  Package[$::ceilometer::params::agent_notification_package_name] -> Service['ceilometer-agent-notification']
  ensure_packages([$::ceilometer::params::agent_notification_package_name])

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Package['ceilometer-common'] -> Service['ceilometer-agent-notification']
  service { 'ceilometer-agent-notification':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::agent_notification_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true
  }

  ceilometer_config {
    'notification/ack_on_event_error': value => $ack_on_event_error;
    'notification/store_events'      : value => $store_events;
  }

}
