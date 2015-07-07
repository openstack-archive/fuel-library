# == Class: swift::auth_file
#
# Create a RC credentials file for Swift v1 authentication
#
# === Parameters:
#
# [*admin_tenant*]
#   (required) The name of the tenant used to authenticate
#
# [*admin_user*]
#   (optional) The name of the user to create in keystone for use by the ironic services
#   Defaults to 'admin'
#
# [*auth_url*]
#   (optional) The authentication URL
#   Defaults to 'http://127.0.0.1:5000/v2.0/'
#
# [*admin_password*]
#   (required) The password for the swift user
#
class swift::auth_file (
  $admin_tenant,
  $admin_password,
  $admin_user      = 'admin',
  $auth_url        = 'http://127.0.0.1:5000/v2.0/'
) {

  file { '/root/swiftrc':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content =>
  "
  export ST_USER=${admin_tenant}:${admin_user}
  export ST_KEY=${admin_password}
  export ST_AUTH=${auth_url}
  ",
  }
}
