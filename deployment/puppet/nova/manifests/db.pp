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
# == Class: nova::db
# Configures the nova database.
#
# == Parameters
#
# [*database_connection*]
#   (optional) Connection url to connect to nova database.
#   Defaults to undef
#
# [*slave_connection*]
#   (optional) Connection url to connect to nova slave database (read-only).
#   Defaults to undef
#
# [*database_idle_timeout*]
#   (optional) Timeout before idle db connections are reaped.
#   Defaults to undef
#
class nova::db (
  $database_connection   = undef,
  $slave_connection      = undef,
  $database_idle_timeout = undef,
) {

  $database_connection_real = pick($database_connection, $::nova::database_connection, false)
  $slave_connection_real = pick($slave_connection, $::nova::slave_connection, false)
  $database_idle_timeout_real = pick($database_idle_timeout, $::nova::database_idle_timeout, false)

  if $database_connection_real {
    if($database_connection_real =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
      require 'mysql::bindings'
      require 'mysql::bindings::python'
    } elsif($database_connection_real =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

    } elsif($database_connection_real =~ /sqlite:\/\//) {

    } else {
      fail("Invalid db connection ${database_connection_real}")
    }
    nova_config {
      'database/connection':   value => $database_connection_real, secret => true;
      'database/idle_timeout': value => $database_idle_timeout_real;
    }
    if $slave_connection_real {
      nova_config {
        'database/slave_connection': value => $slave_connection_real, secret => true;
      }
    } else {
      nova_config {
        'database/slave_connection': ensure => absent;
      }
    }
  }

}
