# == Class: swift::keystone::auth
#
# This class creates keystone users, services, endpoints, and roles
# for Swift services.
#
# The user is given the admin role in the services tenant.
#
# === Parameters
# [*auth_user*]
#  String. The name of the user.
#  Optional. Defaults to 'swift'.
#
# [*password*]
#  String. The user's password.
#  Optional. Defaults to 'swift_password'.
#
# [*operator_roles*]
#  Array of strings. List of roles Swift considers as admin.
#
class swift::keystone::auth(
  $auth_name        = 'swift',
  $password         = 'swift_password',
  $address          = '127.0.0.1',
  $operator_roles   = ['admin', 'SwiftOperator'],
  $internal_address = undef,
  $admin_address    = undef,
  $public_address   = undef,
  $port             = '8080'
) {
  if ($internal_address == undef) {
    $internal_address_real = $address
  } else {
    $internal_address_real = $internal_address
  }

  if ($admin_address == undef) {
    $admin_address_real = $address
  } else {
    $admin_address_real = $admin_address
  }

  if ($public_address == undef) {
    $public_address_real = $address
  } else {
    $public_address_real = $public_address
  }

  keystone_user { $auth_name:
    ensure   => present,
    tenant => 'services',
    password => $password,
  }
  keystone_user_role { "${auth_name}@services":
    ensure  => present,
    roles   => 'admin',
    require => Keystone_user[$auth_name]
  }

  keystone_service { $auth_name:
    ensure      => present,
    type        => 'object-store',
    description => 'Openstack Object-Store Service',
  }
  keystone_endpoint { $auth_name:
    ensure       => present,
    region       => 'RegionOne',
    public_url   => "http://${public_address_real}:${port}/v1/AUTH_%(tenant_id)s",
    admin_url    => "http://${admin_address_real}:${port}/",
    internal_url => "http://${internal_address_real}:${port}/v1/AUTH_%(tenant_id)s",
  }

  keystone_service { "${auth_name}_s3":
    ensure      => present,
    type        => 's3',
    description => 'Openstack S3 Service',
  }
  keystone_endpoint { "${auth_name}_s3":
    ensure       => present,
    region       => 'RegionOne',
    public_url   => "http://${public_address_real}:${port}",
    admin_url    => "http://${admin_address_real}:${port}",
    internal_url => "http://${internal_address_real}:${port}",
  }

  if $operator_roles {
    #Roles like "admin" may be defined elsewhere, so use ensure_resource
    ensure_resource('keystone_role', $operator_roles, { 'ensure' => 'present'})
  }

}
