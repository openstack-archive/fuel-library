class savanna::keystone::auth(
  $password,
  $auth_name        = 'savanna',
  $public_address   = '127.0.0.1',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $savanna_port     = '8386',
  $region           = 'RegionOne',
  $tenant           = 'services',
  $email            = 'savanna@localhost'
) {

  notify {"Keystone":}
  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }


  keystone_service { $auth_name:
    ensure      => present,
    type        => 'orchestration',
    description => 'Openstack_Savanna_Service',
  }
#
  keystone_endpoint { "$auth_name":
    ensure       => present,
    region       => "${region}",
    public_url   => "http://${public_address}:${savanna_port}/v1/%(tenant_id)s",
    internal_url => "http://${internal_address}:${savanna_port}/v1/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${savanna_port}/v1/%(tenant_id)s",
  }

  keystone_user_role { "${auth_name}@${tenant}":
    ensure  => present,
    roles   => 'admin',
  }

}


