# == Class: fuel::ostf::auth
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
class fuel::ostf::auth (
  $auth_name        = $::fuel::params::keystone_ostf_user,
  $password         = $::fuel::params::keystone_ostf_password,
  $address          = $::fuel::params::keystone_host,
  $keystone_domain  = $::fuel::params::keystone_domain,
  $internal_address = undef,
  $admin_address    = undef,
  $public_address   = undef,
  $port             = '8000',
  $region           = 'RegionOne',
  ) inherits fuel::params {
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
    password => $password,
    domain   => $keystone_domain,
  }

  keystone_user_role { "${auth_name}@services":
    ensure         => present,
    roles          => ['admin'],
    user_domain    => $keystone_domain,
    project_domain => $keystone_domain,
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
    type         => 'ostf',
    require      => Keystone_Service['ostf'],
  }
}
