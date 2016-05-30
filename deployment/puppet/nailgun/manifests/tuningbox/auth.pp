class nailgun::tuningbox::auth(
  $address          = $::nailgun::tuningbox::params::keystone_host,
  $auth_name        = $::nailgun::tuningbox::params::keystone_user,
  $password         = $::nailgun::tuningbox::params::keystone_pass,
  $tenant           = $::nailgun::tuningbox::params::keystone_tenant,
  $app_name         = $::nailgun::tuningbox::params::app_name,
  $port             = $::nailgun::tuningbox::params::port,
  $region           = 'RegionOne',
  $internal_address = undef,
  $admin_address    = undef,
  $public_address   = undef,
) inherits nailgun::tuningbox::params {
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
    tenant   => $tenant,
    password => $password,
  }

  keystone_user_role { "${auth_name}@${tenant}":
    ensure => present,
    roles  => 'admin',
  }

  keystone_service { "${app_name}":
    ensure      => present,
    type        => "${app_name}",
    description => "${app_name}",
  }

  keystone_endpoint { "${region}/${app_name}":
    ensure       => present,
    public_url   => "http://${public_address_real}:${port}",
    admin_url    => "http://${admin_address_real}:${port}",
    internal_url => "http://${internal_address_real}:${port}",
  }
}
