class ironic::keystone::auth(
  $user               = $::ironic::params::auth_user,
  $password           = $::ironic::params::auth_password,
  $email              = $::ironic::params::email,
  $service_type       = 'baremetal',
  $tenant             = $::ironic::params::auth_tenant,
  $configure_endpoint = true,
  $region             = 'RegionOne',
  $public_address     = $::ironic::params::ironic_api_public_address,
  $admin_address      = $::ironic::params::ironic_api_admin_address,
  $internal_address   = $::ironic::params::ironic_api_internal_address,
  $port               = $::ironic::params::ironic_api_port,
  ) inherits ironic::params {

   keystone_user { $user:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }

  keystone_user_role { "${user}@${tenant}":
    ensure  => present,
    roles   => 'admin',
  }

  keystone_service { $user:
    ensure      => present,
    type        => $service_type,
    description => "Openstack Baremetal Service",
  }

  if $configure_endpoint {
    keystone_endpoint { $user:
      ensure       => present,
      region       => $region,
      public_url   => "http://${public_address}:${port}",
      admin_url    => "http://${admin_address}:${port}",
      internal_url => "http://${internal_address}:${port}",
    }
  }
}
