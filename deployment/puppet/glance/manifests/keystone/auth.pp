#
# Sets up glance users, service and endpoint
#
# == Parameters:
#
#  $auth_name :: identifier used for all keystone objects related to glance.
#    Optional. Defaults to glance.
#  $password :: password for glance user. Optional. Defaults to glance_password.
#  $service_name :: dentifier service for all keystone objects related to glance.
#  $service_type :: type of service to create. Optional. Defaults to image.
#  $public_address :: Public address for endpoint. Optional. Defaults to 127.0.0.1.
#  $admin_address :: Admin address for endpoint. Optional. Defaults to 127.0.0.1.
#  $inernal_address :: Internal address for endpoint. Optional. Defaults to 127.0.0.1.
#  $port :: Port for endpoint. Needs to match glance api service port. Optional.
#    Defaults to 9292.
#  $region :: Region where endpoint is set.
#  $public_protocol :: Protocol for public endpoint. Optional. Defaults to http.
#  $admin_protocol :: Protocol for admin endpoint. Optional. Defaults to http.
#  $internal_protocol :: Protocol for internal endpoint. Optional. Defaults to http.
#
class glance::keystone::auth(
  $password,
  $email              = 'glance@localhost',
  $auth_name          = 'glance',
  $configure_endpoint = true,
  $service_name       = 'glance',
  $service_type       = 'image',
  $public_address     = '127.0.0.1',
  $admin_address      = '127.0.0.1',
  $internal_address   = '127.0.0.1',
  $port               = '9292',
  $region             = 'RegionOne',
  $tenant             = 'services',
  $public_protocol    = 'http',
  $admin_protocol     = 'http',
  $internal_protocol  = 'http',
  $allow_add_user     = true,
) {

  Keystone_user_role["${auth_name}@${tenant}"]   ~> Service <| name == 'glance-registry' |>
  Keystone_user_role["${auth_name}@${tenant}"]   ~> Service <| name == 'glance-api' |>
  Keystone_endpoint["${region}/${service_name}"] ~> Service <| name == 'glance-api' |>

  if ($allow_add_user != false) {
    keystone_user { $auth_name:
      ensure   => present,
      password => $password,
      email    => $email,
      tenant   => $tenant,
    }
  }

  if !defined(Keystone_user_role["${auth_name}@${tenant}"]) {
    keystone_user_role { "${auth_name}@${tenant}":
      ensure  => present,
      roles   => 'admin',
    }
  }

  keystone_service { $service_name:
    ensure      => present,
    type        => $service_type,
    description => 'Openstack Image Service',
  }

  if $configure_endpoint {
    keystone_endpoint { "${region}/${service_name}":
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${port}",
      admin_url    => "${admin_protocol}://${admin_address}:${port}",
      internal_url => "${internal_protocol}://${internal_address}:${port}",
    }
  }
}
