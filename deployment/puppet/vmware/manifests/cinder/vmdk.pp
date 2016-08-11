#
# Copyright 2016 Mirantis, Inc.
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
# == Define: vmware::cinder::vmdk
#
# This type creates cinder-volume service with VMDK backend,
# which provides block storage solution for
# vSphere's virtual machine instances.
#
# === Parameters
#
# [*vc_insecure*]
#   (optional) If true, the ESX/vCenter server certificate is not verified.
#   If false, then the default CA truststore is used for verification.
#   Defaults to 'True'.
#
# [*vc_ca_file*]
#   (optional) The hash name of the CA bundle file and data in format of:
#   Example:
#   "{"vc_ca_file"=>{"content"=>"RSA", "name"=>"vcenter-ca.pem"}}"
#   Defaults to undef.
#
# [*vc_host*]
#   (required) IP address for connecting to VMware vCenter server.
#   Defaults to '1.2.3.4'.
#
# [*vc_user*]
#   (required) Username for authenticating with VMware vCenter server.
#   Defaults to 'user'.
#
# [*vc_password*]
#   (required) Password for authenticating with VMware vCenter server.
#   Defaults to 'password'.
#
# [*availability_zone_name*]
#   (required) Availability zone of this node and value is used as
#   the default for new volumes.
#   Defaults to 'non-nova'.
#
# [*vc_volume_folder*]
#   (optional) Name of the vCenter inventory folder that will contain
#   Cinder volumes. This folder will be created under
#   "OpenStack/<project_folder>", where project_folder is of format
#   "Project (<volume_project_id>)".
#   Defaults to 'cinder-volumes'.
#
# [*vc_wsdl_location*]
#   (optional) Optional VIM service WSDL Location e.g
#   http://<server>/vimService.wsdl. Optional over-ride to default
#   location for bug work-arounds.
#   Defaults to empty.
#
# [*vc_api_retry_count*]
#   (optional) Number of times VMware vCenter server API must be
#   retried upon connection related issues.
#   Defaults to '10'.
#
# [*vc_host_version*]
#   (optional) Optional string specifying the VMware vCenter
#   server version. The driver attempts to retrieve the version from
#   VMware vCenter server. Set this configuration only if you want
#   to override the vCenter server version.
#   Defaults to empty.
#
# [*vc_image_transfer_timeout_secs*]
#   (optional) Timeout in seconds for VMDK volume transfer
#   between Cinder and Glance.
#   Defaults to '7200'.
#
# [*vc_max_objects_retrieval*]
#   (optional) Max number of objects to be retrieved per batch.
#   Query results will be obtained in batches from the server
#   and not in one shot. Server may still limit the count to
#   something less than the configured value.
#   Defaults to '100'.
#
# [*vc_task_poll_interval*]
#   (optional) The interval (in seconds) for polling remote
#   tasks invoked on VMware vCenter server.
#   Defaults to '5'.
#
# [*vc_tmp_dir*]
#   (optional) Directory where virtual disks are stored during
#   volume backup and restore.
#   Defaults to '/tmp'.
#
# [*cinder_conf_dir*]
#   (optional) The base directory used for cinder-vmware configs.
#   Defaults to '/etc/cinder/cinder.d'.
#
# [*cinder_log_dir*]
#   (optional) The base directory used for relative --log-file paths.
#   Defaults to '/var/log/cinder'.
#
# [*debug*]
#   (optional) Print debugging output (set logging level to DEBUG instead
#   of default WARNING level).
#   Defaults to false.
#
define vmware::cinder::vmdk(
  $vc_insecure                    = true,
  $vc_ca_file                     = undef,
  $vc_host                        = '1.2.3.4',
  $vc_user                        = 'user',
  $vc_password                    = 'password',
  $availability_zone_name         = 'non-nova',
  $vc_volume_folder               = 'cinder-volumes',
  $vc_wsdl_location               = '',
  $vc_api_retry_count             = '10',
  $vc_host_version                = '',
  $vc_image_transfer_timeout_secs = '7200',
  $vc_max_objects_retrieval       = '100',
  $vc_task_poll_interval          = '5',
  $vc_tmp_dir                     = '/tmp',
  $cinder_conf_dir                = '/etc/cinder/cinder.d',
  $cinder_log_dir                 = '/var/log/cinder',
  $debug                          = false,
)
{
  include ::cinder::params
  $index                     = $availability_zone_name
  $cinder_volume_conf        = "${cinder_conf_dir}/vmware-${index}.conf"
  $cinder_volume_vmware      = "${::cinder::params::volume_service}-vmware"
  $storage_hash              = hiera_hash('storage', {})

  if ($storage_hash['volumes_ceph']) and
    (roles_include(['primary-controller']) or
    roles_include(['controller'])) {
    class { '::openstack_tasks::openstack_cinder::openstack_cinder': }
  }

  if ! defined(File[$cinder_conf_dir]) {
    file { $cinder_conf_dir:
      ensure => directory,
      owner  => 'cinder',
      group  => 'cinder',
      mode   => '0750',
    }
  }

  class { '::vmware::ssl::ssl':
      vc_insecure    => $vc_insecure,
      vc_ca_file     => $vc_ca_file,
      vc_ca_filepath => "${cinder_conf_dir}/vcenter-${index}-ca.pem",
  }

  $cinder_vcenter_ca_filepath   = $::vmware::ssl::ssl::vcenter_ca_filepath
  $cinder_vcenter_insecure_real = $::vmware::ssl::ssl::vcenter_insecure_real

  if ! defined (File[$cinder_volume_conf]) {
    file { $cinder_volume_conf:
      ensure  => present,
      content => template('vmware/cinder-volume.conf.erb'),
      mode    => '0600',
      owner   => 'cinder',
      group   => 'cinder',
    }
  }

  File[$cinder_conf_dir]->Class['::vmware::ssl::ssl']->File[$cinder_volume_conf]

  if ! defined(Service['cinder_volume_vmware']) {
    service { 'cinder_volume_vmware':
      ensure    => stopped,
      enable    => false,
      name      => $cinder_volume_vmware,
      hasstatus => true,
    }
  }

  if ! defined(Service["cinder_volume_vmware_${index}"]) {
    service { "cinder_volume_vmware_${index}":
      ensure => running,
      name   => "${cinder_volume_vmware}-${index}",
      enable => true,
    }
  }

  case $::osfamily {
    'RedHat': {
      $src_init                  = $cinder_volume_vmware
      $dst_init                  = '/etc/init.d'
      $file_perm                 = '0755'
      $cinder_volume_vmware_init = "${dst_init}/${cinder_volume_vmware}"
      $init_link                 = "${cinder_volume_vmware_init}-${index}"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => $cinder_volume_vmware_init,
        }
      }

      $cinder_volume_default = "/etc/sysconfig/${cinder_volume_vmware}-${index}"
      if ! defined(File[$cinder_volume_default]){
        file { $cinder_volume_default:
          ensure  => present,
          content => "OPTIONS='--config-file=${cinder_volume_conf}'",
        }
      }
      File[$cinder_volume_default]~>
      Service["cinder_volume_vmware_${index}"]->
      Service['cinder_volume_vmware']
    }
    'Debian': {
      $cinder_volume_default = "/etc/default/${cinder_volume_vmware}-${index}"
      $src_init              = "${cinder_volume_vmware}.conf"
      $dst_init              = '/etc/init'
      $file_perm             = '0644'

      ensure_packages($::cinder::params::volume_package)
      Package[$::cinder::params::volume_package] -> File[$src_init]

      if ! defined(File[$cinder_volume_default]) {
        file { $cinder_volume_default:
          ensure  => present,
          content => "CINDER_VOLUME_OPTS='--config-file=${cinder_volume_conf}'",
        }
      }

      $cinder_volume_vmware_init = "${dst_init}/${cinder_volume_vmware}.conf"
      $init_link = "/etc/init/${cinder_volume_vmware}-${index}.conf"
      if ! defined(File[$init_link]) {
        file { $init_link:
          ensure => link,
          target => $cinder_volume_vmware_init,
        }
      }

      $init_reload_cmd = '/sbin/initctl reload-configuration'
      $init_reload     = 'initctl reload-configuration'
      if ! defined(Exec[$init_reload]) {
        exec { $init_reload:
          command => $init_reload_cmd,
          path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
        }
      }

      File[$cinder_volume_default]~>
      Exec[$init_reload]->
      Service["cinder_volume_vmware_${index}"]->
      Service['cinder_volume_vmware']
    }
    default: {
      fail { "Unsupported OS family (${::osfamily})": }
    }
  }

  if ! defined(File[$src_init]) {
    file { $src_init:
      source => "puppet:///modules/vmware/${src_init}",
      path   => "${dst_init}/${src_init}",
      owner  => 'root',
      group  => 'root',
      mode   => $file_perm,
    }
  }

  File[$src_init]->
  File[$init_link]->
  File[$cinder_volume_default]
}
