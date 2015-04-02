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

#    This type creates cinder-volume service with VMDK backend, which provides
#    block storage solution for vSphere's virtual machine instances.

define vmware::cinder::vmdk(
  $vc_host                        = '1.2.3.4',
  $vc_user                        = 'administrator@vsphere.local',
  $vc_password                    = '',
  $availability_zone_name         = 'non-nova',
  $vc_volume_folder               = 'cinder-volumes',
  $vc_wsdl_location               = '',
  $vc_api_retry_count             = 10,
  $vc_host_version                = '',
  $vc_image_transfer_timeout_secs = 7200,
  $vc_max_objects_retrieval       = 100,
  $vc_task_poll_interval          = 5,
  $vc_tmp_dir                     = '/tmp',
  $cinder_conf_dir                = '/etc/cinder/cinder.d',
  $cinder_log_dir                 = '/var/log/cinder',
  $debug                          = false,
)
{

  include cinder::params
  $index = $availability_zone_name
  $cinder_volume_conf = "${cinder_conf_dir}/vmware-${index}.conf"
  $cinder_volume_log = "${cinder_log_dir}/vmware-${index}.log"
  $cinder_conf = $::cinder::params::cinder_conf
  $cinder_volume_vmware = "${::cinder::params::volume_service}-vmware"

  if ! defined(File[$cinder_conf_dir]) {
    file { $cinder_conf_dir:
      ensure => directory,
      owner  => 'cinder',
      group  => 'cinder',
      mode   => '0750'
    }
  }

  if ! defined (File[$cinder_volume_conf]) {
    file { $cinder_volume_conf:
      ensure  => present,
      content => template('vmware/cinder-volume.conf.erb'),
      mode    => '0600',
      owner   => 'cinder',
      group   => 'cinder',
    }
  }

  File[$cinder_conf_dir]->File[$cinder_volume_conf]

  if ! defined(Service["cinder_volume_vmware_${index}"]) {
    service { "cinder_volume_vmware_${index}":
      ensure => running,
      name   => "${cinder_volume_vmware}-${index}",
      enable => true
    }
  }

  case $::osfamily {
    'RedHat': {
      $src_init = $cinder_volume_vmware
      $dst_init = '/etc/init.d'
      $cinder_volume_vmware_init = "${dst_init}/${cinder_volume_vmware}"
      $init_link = "${cinder_volume_vmware_init}-${index}"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => $cinder_volume_vmware_init
        }
      }

      $cinder_volume_default = "/etc/sysconfig/${cinder_volume_vmware}-${index}"
      if ! defined(File[$cinder_volume_default]){
        file { $cinder_volume_default:
          ensure  => present,
          content => "OPTIONS='--config-file=${cinder_conf} \
          --config-file=${cinder_volume_conf}'",
        }
      }
      File[$cinder_volume_default]~>
      Service["cinder_volume_vmware_${index}"]
    }
    'Debian': {
      $cinder_volume_default = "/etc/default/${cinder_volume_vmware}-${index}"
      $src_init = "${cinder_volume_vmware}.conf"
      $dst_init = '/etc/init'
      if ! defined(File[$cinder_volume_default]) {
        file { $cinder_volume_default:
          ensure  => present,
          content => "CINDER_VOLUME_OPTS='--config-file=${cinder_conf} \
          --config-file=${cinder_volume_conf} --log-file=${cinder_volume_log}'",
        }
      }

      $cinder_volume_vmware_init = "${dst_init}/${cinder_volume_vmware}.conf"
      $init_link = "/etc/init/${cinder_volume_vmware}-${index}.conf"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => $cinder_volume_vmware_init
        }
      }

      $init_reload_cmd = '/sbin/initctl reload-configuration'
      $init_reload = 'initctl reload-configuration'
      if ! defined(Exec[$init_reload]) {
        exec { $init_reload:
          command => $init_reload_cmd,
          path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ]
        }
      }

      File[$cinder_volume_default]~>
      Exec[$init_reload]->
      Service["cinder_volume_vmware_${index}"]
    }
    default: {
      fail { "Unsupported OS family (${::osfamily})": }
    }
  }

  $cmd = "cp /usr/share/cinder/${src_init} ${dst_init}"
  if ! defined(Exec[$src_init]) {
    exec {$src_init:
      command => $cmd,
      path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ]
    }
  }

  Exec[$src_init]->
  File[$init_link]->
  File[$cinder_volume_default]

}
