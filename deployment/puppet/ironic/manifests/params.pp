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
# ironic::params
#

class ironic::params {

  $dbsync_command =
    'ironic-dbsync --config-file /etc/ironic/ironic.conf'

  case $::osfamily {
    'RedHat': {
      $common_package_name = 'openstack-ironic-common'
      $api_package         = 'openstack-ironic-api'
      $api_service         = 'openstack-ironic-api'
      $conductor_package   = 'openstack-ironic-conductor'
      $conductor_service   = 'openstack-ironic-conductor'
      $client_package      = 'python-ironicclient'
    }
    'Debian': {
      $common_package_name = 'ironic-common'
      $api_service         = 'ironic-api'
      $api_package         = 'ironic-api'
      $conductor_service   = 'ironic-conductor'
      $conductor_package   = 'ironic-conductor'
      $client_package      = 'python-ironicclient'
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }

}
