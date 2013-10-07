#    Copyright 2013 Mirantis, Inc.
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
#
#
# these parameters need to be accessed from several locations and
# should be considered to be constant
class galera::params {

  $mysql_user     = "wsrep_sst"
  $mysql_password = "password"

  case $::osfamily {
    'RedHat': {
      $libssl_package       = 'openssl098e'
      $libaio_package       = 'libaio'
      $mysql_version        = '5.5.28_wsrep_23.7-12'
      $mysql_server_name    = 'MySQL-server-wsrep'
      $libgalera_prefix     = '/usr/lib64'
    }
    'Debian': {
      $libssl_package       = 'libssl0.9.8'
      $libaio_package       = 'libaio1'
      $mysql_server_name    = 'mysql-server-wsrep'
      $libgalera_prefix     = '/usr/lib'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

}
