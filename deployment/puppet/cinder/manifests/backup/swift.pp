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
# == Class: cinder::backup::swift
#
# Setup Cinder to backup volumes into Swift
#
# === Parameters
#
# [*backup_swift_url*]
#   (optional) The URL of the Swift endpoint.
#   Should be a valid Swift URL
#   Defaults to 'http://localhost:8080/v1/AUTH_'
#
# [*backup_swift_container*]
#   (optional) The default Swift container to use.
#   Defaults to 'volumes_backup'
#
# [*backup_swift_object_size*]
#   (optional) The size in bytes of Swift backup objects.
#   Defaults to '52428800'
#
# [*backup_swift_retry_attempts*]
#   (optional) The number of retries to make for Swift operations.
#   Defaults to '3'
#
# [*backup_swift_retry_backoff*]
#   (optional) The backoff time in seconds between Swift retries.
#   Defaults to '2'
#

class cinder::backup::swift (
  $backup_driver               = 'cinder.backup.drivers.swift',
  $backup_swift_url            = 'http://localhost:8080/v1/AUTH_',
  $backup_swift_container      = 'volumes_backup',
  $backup_swift_object_size    = '52428800',
  $backup_swift_retry_attempts = '3',
  $backup_swift_retry_backoff  = '2'
) {

  cinder_config {
    'DEFAULT/backup_driver':               value => $backup_driver;
    'DEFAULT/backup_swift_url':            value => $backup_swift_url;
    'DEFAULT/backup_swift_container':      value => $backup_swift_container;
    'DEFAULT/backup_swift_object_size':    value => $backup_swift_object_size;
    'DEFAULT/backup_swift_retry_attempts': value => $backup_swift_retry_attempts;
    'DEFAULT/backup_swift_retry_backoff':  value => $backup_swift_retry_backoff;
  }

}
