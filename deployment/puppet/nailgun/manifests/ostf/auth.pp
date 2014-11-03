# == Class: nailgun::ostf:auth
#
# This class creates keystone users, services, endpoints, and roles
# for OSTF services.
#
# The user is given the admin role in the services tenant.
#
# === Parameters
# [*auth_user*]
#  String. The name of the user.
#  Optional. Defaults to 'ostf'.
#
# [*password*]
#  String. The user's password.
#  Optional. Defaults to 'ostf'.
#
class nailgun::ostf::auth(
  $auth_name        = 'ostf',
  $password         = 'ostf',
  $address          = '127.0.0.1',
  $internal_address = undef,
  $admin_address    = undef,
  $public_address   = undef,
  $port             = '8000',
  $region           = 'RegionOne',
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
    enabled  => 'True',
    tenant   => 'services',
    password => $password,
  }

  keystone_user_role { "${auth_name}@services":
    ensure => present,
    roles  => 'admin',
  }

  keystone_service { 'ostf':
    ensure      => present,
    type        => 'ostf',
    description => 'OSTF',
  }

  keystone_endpoint { "$region/ostf":
    ensure       => present,
    public_url   => "http://${public_address_real}:${port}/ostf",
    admin_url    => "http://${admin_address_real}:${port}/ostf",
    internal_url => "http://${internal_address_real}:${port}/ostf",
  }
}
