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
# Author: Andrew Woodward <awoodward@mirantis.com>
class cinder::backends (
  $enabled_backends    = undef,
  # DEPRECATED
  $default_volume_type = false
  ){

  # Maybe this could be extented to dynamicly find the enabled names
  cinder_config {
    'DEFAULT/enabled_backends': value => join($enabled_backends, ',');
  }

  if $default_volume_type {
    fail('The default_volume_type parameter is deprecated in this class, you should declare it in cinder::api.')
  }

}
