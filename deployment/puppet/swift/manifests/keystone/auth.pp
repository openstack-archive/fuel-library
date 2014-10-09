# == Class: swift::keystone::auth
#
# This class creates keystone users, services, endpoints, and roles
# for swift services.
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
  $auth_name              = 'swift',
  $password               = 'swift_password',
  $port                   = '8080',
  $tenant                 = 'services',
  $email                  = 'swift@localhost',
  $region                 = 'RegionOne',
  $operator_roles         = ['admin', 'SwiftOperator'],
  $public_protocol        = 'http',
  $public_address         = '127.0.0.1',
  $public_port            = undef,
  $admin_protocol         = 'http',
  $admin_address          = undef,
  $internal_protocol      = 'http',
  $internal_address       = undef,
  $configure_endpoint     = true,
  $configure_s3_endpoint  = true,
  $endpoint_prefix        = 'AUTH',
) {

  if ! $public_port {
    $real_public_port = $port
  } else {
    $real_public_port = $public_port
  }
  if ! $admin_address {
    $real_admin_address = $public_address
  } else {
    $real_admin_address = $admin_address
  }
  if ! $internal_address {
    $real_internal_address = $public_address
  } else {
    $real_internal_address = $internal_address
  }

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }
  keystone_user_role { "${auth_name}@${tenant}":
    ensure  => present,
    roles   => 'admin',
    require => Keystone_user[$auth_name]
  }

  keystone_service { $auth_name:
    ensure      => present,
    type        => 'object-store',
    description => 'Openstack Object-Store Service',
  }

  if $configure_endpoint {
    keystone_endpoint { "${region}/${auth_name}":
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${real_public_port}/v1/${endpoint_prefix}_%(tenant_id)s",
      admin_url    => "${admin_protocol}://${real_admin_address}:${port}/",
      internal_url => "${internal_protocol}://${real_internal_address}:${port}/v1/${endpoint_prefix}_%(tenant_id)s",
    }
  }

  if $configure_s3_endpoint {
    keystone_service { "${auth_name}_s3":
      ensure      => present,
      type        => 's3',
      description => 'Openstack S3 Service',
    }

    keystone_endpoint { "${region}/${auth_name}_s3":
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${real_public_port}",
      admin_url    => "${admin_protocol}://${real_admin_address}:${port}",
      internal_url => "${internal_protocol}://${real_internal_address}:${port}",
    }
  }

  if $operator_roles {
    #Roles like "admin" may be defined elsewhere, so use ensure_resource
    ensure_resource('keystone_role', $operator_roles, { 'ensure' => 'present' })
  }

}
