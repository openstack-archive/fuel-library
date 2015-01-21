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
# == Definition: openstacklib::messaging::rabbitmq
#
# This resource creates RabbitMQ resources for an OpenStack service.
#
# == Parameters:
#
# [*userid*]
#   (optional) The username to use when connecting to Rabbit
#   Defaults to 'guest'
#
# [*password*]
#   (optional) The password to use when connecting to Rabbit
#   Defaults to 'guest'
#
# [*virtual_host*]
#   (optional) The virtual host to use when connecting to Rabbit
#   Defaults to '/'
#
# [*is_admin*]
#   (optional) If the user should be admin or not
#   Defaults to false
#
# [*configure_permission*]
#   (optional) Define configure permission
#   Defaults to '.*'
#
# [*write_permission*]
#   (optional) Define write permission
#   Defaults to '.*'
#
# [*read_permission*]
#   (optional) Define read permission
#   Defaults to '.*'
#
# [*manage_user*]
#   (optional) Manage or not the user
#   Defaults to true
#
# [*manage_user_permissions*]
#   (optional) Manage or not user permissions
#   Defaults to true
#
# [*manage_vhost*]
#   (optional) Manage or not the vhost
#   Defaults to true
#
define openstacklib::messaging::rabbitmq(
  $userid                  = 'guest',
  $password                = 'guest',
  $virtual_host            = '/',
  $is_admin                = false,
  $configure_permission    = '.*',
  $write_permission        = '.*',
  $read_permission         = '.*',
  $manage_user             = true,
  $manage_user_permissions = true,
  $manage_vhost            = true,
) {

  if $manage_user {
    if $userid == 'guest' {
      $is_admin_real = false
    } else {
      $is_admin_real = $is_admin
    }
    ensure_resource('rabbitmq_user', $userid, {
      'admin'    => $is_admin_real,
      'password' => $password,
      'provider' => 'rabbitmqctl',
    })
  }

  if $manage_user_permissions {
    ensure_resource('rabbitmq_user_permissions', "${userid}@${virtual_host}", {
      'configure_permission' => $configure_permission,
      'write_permission'     => $write_permission,
      'read_permission'      => $read_permission,
      'provider'             => 'rabbitmqctl',
    })
  }

  if $manage_vhost {
    ensure_resource('rabbitmq_vhost', $virtual_host, {
      'provider' => 'rabbitmqctl',
    })
  }

}
