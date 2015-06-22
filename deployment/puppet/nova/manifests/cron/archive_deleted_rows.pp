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
# == Class: nova::cron::archive_deleted_rows
#
# Move deleted instances to another table that you don't have to backup
# unless you have data retention policies.
#
# === Parameters
#
#  [*minute*]
#    (optional) Defaults to '1'.
#
#  [*hour*]
#    (optional) Defaults to '0'.
#
#  [*monthday*]
#    (optional) Defaults to '*'.
#
#  [*month*]
#    (optional) Defaults to '*'.
#
#  [*weekday*]
#    (optional) Defaults to '*'.
#
#  [*max_rows*]
#    (optional) Maximum number of deleted rows to archive.
#    Defaults to '100'.
#
#  [*user*]
#    (optional) User with access to nova files.
#    Defaults to 'nova'.
#
class nova::cron::archive_deleted_rows (
  $minute   = 1,
  $hour     = 0,
  $monthday = '*',
  $month    = '*',
  $weekday  = '*',
  $max_rows = '100',
  $user     = 'nova',
) {

  cron { 'nova-manage db archive_deleted_rows':
    command     => "nova-manage db archive_deleted_rows --max_rows ${max_rows} >>/var/log/nova/nova-rowsflush.log 2>&1",
    environment => 'PATH=/bin:/usr/bin:/usr/sbin SHELL=/bin/sh',
    user        => $user,
    minute      => $minute,
    hour        => $hour,
    monthday    => $monthday,
    month       => $month,
    weekday     => $weekday,
    require     => Package['nova-common'],
  }
}
