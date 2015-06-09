# == Class: neutron::keystone::auth
#
# Configures Neutron user, service and endpoint in Keystone.
#
# === Parameters
#
# [*password*]
#   (required) Password for Neutron user.
#
# [*auth_name*]
#   Username for Neutron service. Defaults to 'neutron'.
#
# [*email*]
#   Email for Neutron user. Defaults to 'neutron@localhost'.
#
# [*tenant*]
#   Tenant for Neutron user. Defaults to 'services'.
#
# [*configure_endpoint*]
#   Should Neutron endpoint be configured? Defaults to 'true'.
#
# [*configure_user*]
#   Should the Neutron service user be configured? Defaults to 'true'.
#
# [*configure_user_role*]
#   Should the admin role be configured for the service user?
#   Defaults to 'true'.
#
# [*service_name*]
#   Name of the service. Defaults to the value of auth_name.
#
# [*service_type*]
#   Type of service. Defaults to 'network'.
#
# [*public_protocol*]
#   Protocol for public endpoint. Defaults to 'http'.
#
# [*public_address*]
#   Public address for endpoint. Defaults to '127.0.0.1'.
#
# [*admin_protocol*]
#   Protocol for admin endpoint. Defaults to 'http'.
#
# [*admin_address*]
#   Admin address for endpoint. Defaults to '127.0.0.1'.
#
# [*internal_protocol*]
#   Protocol for internal endpoint. Defaults to 'http'.
#
# [*internal_address*]
#   Internal address for endpoint. Defaults to '127.0.0.1'.
#
# [*port*]
#   Port for endpoint. Defaults to '9696'.
#
# [*public_port*]
#   Port for public endpoint. Defaults to $port.
#
# [*region*]
#   Region for endpoint. Defaults to 'RegionOne'.
#
class neutron::keystone::auth (
  $password,
  $auth_name           = 'neutron',
  $email               = 'neutron@localhost',
  $tenant              = 'services',
  $configure_endpoint  = true,
  $configure_user      = true,
  $configure_user_role = true,
  $service_name        = undef,
  $service_type        = 'network',
  $public_protocol     = 'http',
  $public_address      = '127.0.0.1',
  $admin_protocol      = 'http',
  $admin_address       = '127.0.0.1',
  $internal_protocol   = 'http',
  $internal_address    = '127.0.0.1',
  $port                = '9696',
  $public_port         = undef,
  $region              = 'RegionOne'
) {

  if $service_name == undef {
    $real_service_name = $auth_name
  } else {
    $real_service_name = $service_name
  }

  if ! $public_port {
    $real_public_port = $port
  } else {
    $real_public_port = $public_port
  }

  Keystone_endpoint["${region}/${real_service_name}"]  ~> Service <| name == 'neutron-server' |>

  if $configure_user {
    keystone_user { $auth_name:
      ensure   => present,
      password => $password,
      email    => $email,
      tenant   => $tenant,
    }
  }

  if $configure_user_role {
    Keystone_user_role["${auth_name}@${tenant}"] ~> Service <| name == 'neutron-server' |>

    keystone_user_role { "${auth_name}@${tenant}":
      ensure => present,
      roles  => 'admin',
    }
  }

  keystone_service { $real_service_name:
    ensure      => present,
    type        => $service_type,
    description => 'Neutron Networking Service',
  }

  if $configure_endpoint {
    keystone_endpoint { "${region}/${real_service_name}":
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${real_public_port}/",
      internal_url => "${internal_protocol}://${internal_address}:${port}/",
      admin_url    => "${admin_protocol}://${admin_address}:${port}/",
    }

  }
}
