#    Copyright 2015 Mirantis, Inc.
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
# == Define: galera::client
#
# Class for installation and configuration of mysql-client
#
# === Parameters
#
# [*custom_setup_class*]
#  Custom mysql and galera setup class.
#
class openstack::galera::client (
  $custom_setup_class = 'galera',
) {

  if $custom_setup_class == 'percona' {
    $use_percona          = true
    $use_percona_packages = false
  } elsif ($custom_setup_class == 'percona_packages') {
    $use_percona          = true
    $use_percona_packages = true
  } else {
    $use_percona          = false
    $use_percona_packages = false
  }

  if ($use_percona) {
    case $::osfamily {
      'RedHat': {
        if ($use_percona_packages) {
          $mysql_client_name = 'Percona-XtraDB-Cluster-client-56'
        } else {
          fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only supports Debian when not using the Percona packages")
        }
      }
      'Debian': {
        if ($use_percona_packages) {
          $mysql_client_name = 'percona-xtradb-cluster-client-5.6'
        } else {
          $mysql_client_name = 'percona-xtradb-cluster-client-5.5'
        }
      }
      default: {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
      }
    }
  } else {
    $mysql_client_name = 'mysql-wsrep-client-5.6'
  }

  class { 'mysql::client':
    package_name => $mysql_client_name,
  }
}
