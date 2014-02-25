class savanna::keystone::auth (
  $password         = 'savanna',
  $auth_name        = 'savanna',
  $public_address   = '127.0.0.1',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $savanna_port     = '8386',
  $region           = 'RegionOne',
  $tenant           = 'services',
  $email            = 'savanna@localhost'
) {

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }

  keystone_service { $auth_name:
    ensure      => present,
    type        => 'data_processing',
    description => 'Savanna Data Processing',
  }

  keystone_endpoint { $auth_name:
    ensure       => present,
    region       => $region,
    public_url   => "http://${public_address}:${savanna_port}/v1.1/%(tenant_id)s",
    internal_url => "http://${internal_address}:${savanna_port}/v1.1/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${savanna_port}/v1.1/%(tenant_id)s",
  }

  keystone_user_role { "${auth_name}@${tenant}":
    ensure  => present,
    roles   => 'admin',
  }

}


