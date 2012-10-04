#
# Sets up glance users, service and endpoint
#
# == Parameters:
#
#  $auth_name :: identifier used for all keystone objects related to glance.
#    Optional. Defaults to glance.
#  $password :: password for glance user. Optional. Defaults to glance_password.
#  $service_type :: type of service to create. Optional. Defaults to image.
#  $public_address :: Public address for endpoint. Optional. Defaults to 127.0.0.1.
#  $admin_address :: Admin address for endpoint. Optional. Defaults to 127.0.0.1.
#  $inernal_address :: Internal address for endpoint. Optional. Defaults to 127.0.0.1.
#  $port :: Port for endpoint. Needs to match glance api service port. Optional.
#    Defaults to 9292.
#  $region :: Region where endpoint is set.
#
class glance::keystone::auth(
  $auth_name          = 'glance',
  $password           = 'glance_password',
  $configure_endpoint = true,
  $service_type       = 'image',
  $public_address     = '127.0.0.1',
  $admin_address      = '127.0.0.1',
  $internal_address   = '127.0.0.1',
  $port               = '9292',
  $region             = 'RegionOne',
  $email              = 'glance@localhost',
  $tenant             = 'services'
) {

  Keystone_user_role["${auth_name}@${tenant}"] ~> Service <| name == 'glance-registry' |>
  Keystone_user_role["${auth_name}@${tenant}"] ~> Service <| name == 'glance-api' |>

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }
  keystone_user_role { "${auth_name}@${tenant}":
    ensure  => present,
    roles   => 'admin',
  }
  keystone_service { $auth_name:
    ensure      => present,
    type        => $service_type,
    description => "Openstack Image Service",
  }
  if $configure_endpoint {
    keystone_endpoint { $auth_name:
      ensure       => present,
      region       => $region,
      public_url   => "http://${public_address}:${port}/v1",
      admin_url    => "http://${admin_address}:${port}/v1",
      internal_url => "http://${internal_address}:${port}/v1",
    }
  }
}
