# == Class: nova::compute::ironic
#
# Configures Nova compute service to use Ironic.
#
# === Parameters:
#
# [*admin_username*]
#   The admin username for Ironic to connect to Nova.
#   Defaults to 'admin'
#
# [*admin_password*]
#   The admin password for Ironic to connect to Nova.
#   Defaults to 'ironic'
#
# [*admin_url*]
#   The address of the Keystone api endpoint.
#   Defaults to 'http://127.0.0.1:35357/v2.0'
#
# [*admin_tenant_name*]
#   The Ironic Keystone tenant name.
#   Defaults to 'services'
#
# [*api_endpoint*]
#   The url for Ironic api endpoint.
#   Defaults to 'http://127.0.0.1:6385/v1'
#
# [*compute_driver*]
#   (optional) Compute driver.
#   Defaults to 'ironic.IronicDriver'
#
# [*admin_user*]
#   (optional) DEPRECATED: Use admin_username instead.
#
# [*admin_passwd*]
#   (optional) DEPRECATED: Use admin_password instead.
#
class nova::compute::ironic (
  $admin_username       = 'admin',
  $admin_password       = 'ironic',
  $admin_url            = 'http://127.0.0.1:35357/v2.0',
  $admin_tenant_name    = 'services',
  $api_endpoint         = 'http://127.0.0.1:6385/v1',
  # DEPRECATED PARAMETERS
  $admin_user           = undef,
  $admin_passwd         = undef,
  $compute_driver       = 'ironic.IronicDriver'
) {

  if $admin_user {
    warning('The admin_user parameter is deprecated, use admin_username instead.')
  }

  if $admin_passwd {
    warning('The admin_passwd parameter is deprecated, use admin_password instead.')
  }

  $admin_username_real = pick($admin_user, $admin_username)
  $admin_password_real = pick($admin_passwd, $admin_password)

  nova_config {
    'ironic/admin_username':            value => $admin_username_real;
    'ironic/admin_password':            value => $admin_password_real;
    'ironic/admin_url':                 value => $admin_url;
    'ironic/admin_tenant_name':         value => $admin_tenant_name;
    'ironic/api_endpoint':              value => $api_endpoint;
    'DEFAULT/compute_driver':           value => $compute_driver;
  }
}
