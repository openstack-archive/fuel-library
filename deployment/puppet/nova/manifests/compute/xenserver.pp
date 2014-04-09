# == Class: nova::compute::xenserver
#
# Configures nova-compute to manage xen guests
#
# === Parameters:
#
# [*xenapi_connection_url*]
#   (required) URL for connection to XenServer/Xen Cloud Platform.
#
# [*xenapi_connection_username*]
#   (required) Username for connection to XenServer/Xen Cloud Platform
#
# [*xenapi_connection_password*]
#   (required) Password for connection to XenServer/Xen Cloud Platform
#
# [*xenapi_inject_image*]
#   (optional) This parameter was removed in Diablo and does nothing.
#   Defaults to false
#
class nova::compute::xenserver(
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $xenapi_inject_image=false
) {

  nova_config {
    'DEFAULT/compute_driver':             value => 'xenapi.XenAPIDriver';
    'DEFAULT/connection_type':            value => 'xenapi';
    'DEFAULT/xenapi_connection_url':      value => $xenapi_connection_url;
    'DEFAULT/xenapi_connection_username': value => $xenapi_connection_username;
    'DEFAULT/xenapi_connection_password': value => $xenapi_connection_password;
    'DEFAULT/xenapi_inject_image':        value => $xenapi_inject_image;
  }

  ensure_packages(['python-pip'])

  package { 'xenapi':
    ensure   => present,
    provider => pip
  }

  Package['python-pip'] -> Package['xenapi']
}
