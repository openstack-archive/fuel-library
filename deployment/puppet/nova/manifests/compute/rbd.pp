#
# Copyright (C) 2014 OpenStack Fondation
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#         Donald Talton  <dotalton@cisco.com>
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

# == Class: nova::compute::rbd
#
# Configure nova-compute to store virtual machines on RBD
#
# === Parameters
#
# [*libvirt_images_rbd_pool*]
#   (optional) The RADOS pool in which rbd volumes are stored.
#   Defaults to 'rbd'.
#
# [*libvirt_images_rbd_ceph_conf*]
#   (optional) The path to the ceph configuration file to use.
#   Defaults to '/etc/ceph/ceph.conf'.
#
# [*libvirt_rbd_user*]
#   (Required) The RADOS client name for accessing rbd volumes.
#
# [*libvirt_rbd_secret_uuid*]
#   (optional) The libvirt uuid of the secret for the rbd_user.
#   Required to use cephx.
#   Default to false.
#

class nova::compute::rbd (
  $libvirt_rbd_user,
  $libvirt_rbd_secret_uuid      = false,
  $libvirt_images_rbd_pool      = 'rbd',
  $libvirt_images_rbd_ceph_conf = '/etc/ceph/ceph.conf',
) {

  include nova::params

  nova_config {
    'libvirt/images_type':          value => 'rbd';
    'libvirt/images_rbd_pool':      value => $libvirt_images_rbd_pool;
    'libvirt/images_rbd_ceph_conf': value => $libvirt_images_rbd_ceph_conf;
    'libvirt/rbd_user':             value => $libvirt_rbd_user;
  }

  if $libvirt_rbd_secret_uuid {
    nova_config {
      'libvirt/rbd_secret_uuid': value => $libvirt_rbd_secret_uuid;
    }

    file { '/etc/nova/secret.xml':
      content => template('nova/secret.xml-compute.erb')
    }

    exec { 'get-or-set virsh secret':
      command => '/usr/bin/virsh secret-define --file /etc/nova/secret.xml | /usr/bin/awk \'{print $2}\' | sed \'/^$/d\' > /etc/nova/virsh.secret',
      creates => '/etc/nova/virsh.secret',
      require => File['/etc/nova/secret.xml']
    }

    exec { 'set-secret-value virsh':
      command => '/usr/bin/virsh secret-set-value --secret $(cat /etc/nova/virsh.secret) --base64 $(ceph auth get-key client.nova)',
      require => Exec['get-or-set virsh secret']
    }

  }

}
