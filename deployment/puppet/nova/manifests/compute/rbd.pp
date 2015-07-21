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
# [*libvirt_rbd_secret_key*]
#   (optional) The cephx key to use as key for the libvirt secret,
#   it must be base64 encoded; when not provided this key will be
#   requested to the ceph cluster, which assumes the node is
#   provided of the client.admin keyring as well.
#   Default to undef.
#
# [*rbd_keyring*]
#   (optional) The keyring name to use when retrieving the RBD secret
#   Default to 'client.nova'
#
# [*ephemeral_storage*]
#   (optional) Wether or not to use the rbd driver for the nova
#   ephemeral storage or for the cinder volumes only.
#   Defaults to true.
#

class nova::compute::rbd (
  $libvirt_rbd_user,
  $libvirt_rbd_secret_uuid      = false,
  $libvirt_rbd_secret_key       = undef,
  $libvirt_images_rbd_pool      = 'rbd',
  $libvirt_images_rbd_ceph_conf = '/etc/ceph/ceph.conf',
  $rbd_keyring                  = 'client.nova',
  $ephemeral_storage            = true,
) {

  include ::nova::params

  nova_config {
    'libvirt/rbd_user': value => $libvirt_rbd_user;
  }

  if $libvirt_rbd_secret_uuid {
    nova_config {
      'libvirt/rbd_secret_uuid': value => $libvirt_rbd_secret_uuid;
    }

    file { '/etc/nova/secret.xml':
      content => template('nova/secret.xml-compute.erb'),
      require => Class['::nova']
    }

    exec { 'get-or-set virsh secret':
      command => '/usr/bin/virsh secret-define --file /etc/nova/secret.xml | /usr/bin/awk \'{print $2}\' | sed \'/^$/d\' > /etc/nova/virsh.secret',
      creates => '/etc/nova/virsh.secret',
      require => File['/etc/nova/secret.xml']
    }

    if $libvirt_rbd_secret_key {
      $libvirt_key = $libvirt_rbd_secret_key
    } else {
      $libvirt_key = "$(ceph auth get-key ${rbd_keyring})"
    }
    exec { 'set-secret-value virsh':
      command => "/usr/bin/virsh secret-set-value --secret ${libvirt_rbd_secret_uuid} --base64 ${libvirt_key}",
      unless  => "/usr/bin/virsh secret-get-value ${libvirt_rbd_secret_uuid}",
      require => Exec['get-or-set virsh secret']
    }

  }

  if $ephemeral_storage {
    nova_config {
      'libvirt/images_type':          value => 'rbd';
      'libvirt/images_rbd_pool':      value => $libvirt_images_rbd_pool;
      'libvirt/images_rbd_ceph_conf': value => $libvirt_images_rbd_ceph_conf;
    }
  } else {
    nova_config {
      'libvirt/images_rbd_pool':      ensure => absent;
      'libvirt/images_rbd_ceph_conf': ensure => absent;
    }
  }

}
