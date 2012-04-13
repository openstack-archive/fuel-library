class glance::keystone::auth(
  $auth_name = 'glance',
  $password  = 'glance_password',
  $service   = 'image',
  $address   = '127.0.0.1',
  $port      = '9292'
) {

  Keystone_user_role["${auth_name}@services"] ~> Service <| name == 'glance-registry' |>
  Keystone_user_role["${auth_name}@services"] ~> Service <| name == 'glance-api' |>

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
  }
  keystone_user_role { "${auth_name}@services":
    ensure  => present,
    roles   => 'admin',
  }
  keystone_service { $auth_name:
    ensure      => present,
    type        => 'image',
    description => "Openstack Image Service",
  }
  keystone_endpoint { $auth_name:
    ensure       => present,
    region       => 'RegionOne',
    public_url   => "http://${address}:${port}/v1",
    admin_url    => "http://${address}:${port}/v1",
    internal_url => "http://${address}:${port}/v1",
  }

}
