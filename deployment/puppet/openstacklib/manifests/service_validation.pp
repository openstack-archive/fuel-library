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
# == Definition: openstacklib::service_validation
#
# This resource does service validation for an OpenStack service.
#
# == Parameters:
#
# [*command*]
# Command to run for validating the service;
# string; required
#
# [*service_name*]
# The name of the service to validate;
# string; optional; default to the $title of the resource, i.e. 'nova-api'
#
# [*path*]
# The path of the command to validate the service;
# string; optional; default to '/usr/bin:/bin:/usr/sbin:/sbin'
#
# [*provider*]
# The provider to use for the exec command;
# string; optional; default to 'shell'
#
# [*tries*]
# Number of times to retry validation;
# string; optional; default to '10'
#
# [*try_sleep*]
# Number of seconds between validation attempts;
# string; optional; default to '2'
#
define openstacklib::service_validation(
  $command,
  $service_name = $name,
  $path         = '/usr/bin:/bin:/usr/sbin:/sbin',
  $provider     = shell,
  $tries        = '10',
  $try_sleep    = '2',
) {

  exec { "execute ${service_name} validation":
    path      => $path,
    provider  => $provider,
    command   => $command,
    tries     => $tries,
    try_sleep => $try_sleep,
  }

  anchor { "create ${service_name} anchor":
    require => Exec["execute ${service_name} validation"],
  }

}
