# == Class: osnailyfacter::openstack::manage_cinder_types
#
# Wrapper resource to allow the management of cinder types using hashes from
# the hiera data.
#
# === Parameters
#
# [*ensure*]
#  (optional) Should the type be 'present' or 'absent'
#  Defaults to 'present'
#
# [*volume_backend_names*]
#  (optional) A hash with the cinder type data to set with the cinder_type
#  provider. If ensure is set to 'present', this should be an hash with a value
#  for the $name provided to this resource.
#  Defaults to {}
#
# [*key*]
#  (optional) The name of the key to set for the cinder_type.
#  Defaults to 'volume_backend_name'
#
define osnailyfacter::openstack::manage_cinder_types (
  $ensure               = 'present',
  $volume_backend_names = {},
  $key                  = 'volume_backend_name',
) {
  if $ensure == 'present' {
    $value = $volume_backend_names[$name]
    cinder_type { $name:
      properties => ["${key}=${value}"]
    }
  } else {
    cinder_type { $name:
      ensure => absent
    }
  }
}
