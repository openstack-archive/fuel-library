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
# == Class: cinder::backup
#
# Setup Cinder backup service
#
# === Parameters
#
# [*backup_topic*]
#   (optional) The topic volume backup nodes listen on.
#   Defaults to 'cinder-backup'
#
# [*backup_manager*]
#   (optional) Full class name for the Manager for volume backup.
#   Defaults to 'cinder.backup.manager.BackupManager'
#
# [*backup_api_class*]
#   (optional) The full class name of the volume backup API class.
#   Defaults to 'cinder.backup.api.API'
#
# [*backup_name_template*]
#   (optional) Template string to be used to generate backup names.
#   Defaults to 'backup-%s'
#

class cinder::backup (
  $enabled              = true,
  $package_ensure       = 'present',
  $backup_topic         = 'cinder-backup',
  $backup_manager       = 'cinder.backup.manager.BackupManager',
  $backup_api_class     = 'cinder.backup.api.API',
  $backup_name_template = 'backup-%s'
) {

  include cinder::params

  Cinder_config<||> ~> Service['cinder-backup']

  if $::cinder::params::backup_package {
    Package['cinder-backup'] -> Cinder_config<||>
    Package['cinder-backup'] -> Service['cinder-backup']
    package { 'cinder-backup':
      ensure => $package_ensure,
      name   => $::cinder::params::backup_package,
    }
  }

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  service { 'cinder-backup':
    ensure    => $ensure,
    name      => $::cinder::params::backup_service,
    enable    => $enabled,
    hasstatus => true,
    require   => Package['cinder'],
  }

  cinder_config {
    'DEFAULT/backup_topic':         value => $backup_topic;
    'DEFAULT/backup_manager':       value => $backup_manager;
    'DEFAULT/backup_api_class':     value => $backup_api_class;
    'DEFAULT/backup_name_template': value => $backup_name_template;
  }

}
