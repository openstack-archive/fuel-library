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

# Configure the PXE driver in Ironic
#
# === Parameters
#
# [*deploy_kernel*]
#   (optional) Default kernel image ID used in deployment phase.
#   Should be an valid id
#   Defaults to undef.
#
# [*deploy_ramdisk*]
#   (optional) Default kernel image ID used in deployment phase.
#   Should be an valid id
#   Defaults to undef.
#
# [*pxe_append_params*]
#   (optional) Additional append parameters for baremetal PXE boot.
#   Should be valid pxe parameters
#   Defaults to 'nofb nomodeset vga=normal'.
#
# [*pxe_config_template*]
#   (optional) Template file for PXE configuration.
#   Should be an valid template file
#   Defaults to '$pybasedir/drivers/modules/pxe_config.template'.
#
# [*pxe_deploy_timeout*]
#   (optional) Timeout for PXE deployments.
#   Should be an valid integer
#   Defaults to '0' for unlimited.
#
# [*tftp_server*]
#   (optional) IP address of Ironic compute node's tftp server.
#   Should be an valid IP address
#   Defaults to '$my_ip'.
#
# [*tftp_root*]
#   (optional) Ironic compute node's tftp root path.
#   Should be an valid path
#   Defaults to '/tftpboot'.
#
# [*images_path*]
#   (optional) Directory where images are stored on disk.
#   Should be an valid directory
#   Defaults to '/tftpboot'.
#
# [*tftp_master_path*]
#   (optional) Directory where master tftp images are stored on disk.
#   Should be an valid directory
#   Defaults to '/tftpboot/master_images'.
#
# [*instance_master_path*]
#   (optional) Directory where master tftp images are stored on disk.
#   Should be an valid directory
#   Defaults to '/var/lib/ironic/master_images'.
#

class ironic::drivers::pxe (
  $deploy_kernel        = undef,
  $deploy_ramdisk       = undef,
  $pxe_append_params    = 'nofb nomodeset vga=normal',
  $pxe_config_template  = '$pybasedir/drivers/modules/pxe_config.template',
  $pxe_deploy_timeout   = '0',
  $tftp_server          = '$my_ip',
  $tftp_root            = '/tftpboot',
  $images_path          = '/var/lib/ironic/images/',
  $tftp_master_path     = '/tftpboot/master_images',
  $instance_master_path = '/var/lib/ironic/master_images',
) {

  # Configure ironic.conf
  ironic_config {
    'pxe/pxe_append_params': value    => $pxe_append_params;
    'pxe/pxe_config_template': value  => $pxe_config_template;
    'pxe/pxe_deploy_timeout': value   => $pxe_deploy_timeout;
    'pxe/tftp_server': value          => $tftp_server;
    'pxe/tftp_root': value            => $tftp_root;
    'pxe/images_path': value          => $images_path;
    'pxe/tftp_master_path': value     => $tftp_master_path;
    'pxe/instance_master_path': value => $instance_master_path;
  }

  if $deploy_kernel {
    ironic_config {
      'pxe/deploy_kernel': value => $deploy_kernel;
    }
  }

  if $deploy_ramdisk {
    ironic_config {
      'pxe/deploy_ramdisk': value => $deploy_ramdisk;
    }
  }

}
