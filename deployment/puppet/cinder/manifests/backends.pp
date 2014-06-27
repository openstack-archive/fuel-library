# == Class: cinder::backends
#
# Class to set the enabled_backends list
#
# === Parameters
#
# [*enabled_backends*]
#   (required) a list of ini sections to enable.
#     This should contain names used in ceph::backend::* resources.
#     Example: ['volume1', 'volume2', 'sata3']
#
# [*default_volume_type*]
#   (optional) default volume type to use.
#   This should contain the name of the default volume type to use.
#   If not configured, it produces an error when creating a volume
#   without specifying a type.
#   Defaults to 'false'.
#
# Author: Andrew Woodward <awoodward@mirantis.com>
class cinder::backends (
  $enabled_backends    = undef,
  $default_volume_type = false
  ){

  # Maybe this could be extented to dynamicly find the enabled names
  cinder_config {
    'DEFAULT/enabled_backends': value => join($enabled_backends, ',');
  }

  if $default_volume_type {
    cinder_config {
      'DEFAULT/default_volume_type': value => $default_volume_type;
    }
  } else {
    cinder_config {
      'DEFAULT/default_volume_type': ensure => absent;
    }
  }

}
