class sahara::keystone::auth (
  $password         = 'sahara',
  $auth_name        = 'sahara',
  $service_name     = 'sahara',
  $public_address   = '127.0.0.1',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $sahara_port      = '8386',
  $region           = 'RegionOne',
  $tenant           = 'services',
  $email            = 'sahara@localhost',
  $allow_add_user   = true,
) {

  if ($allow_add_user != false) {
    keystone_user { $auth_name:
      ensure   => present,
      password => $password,
      email    => $email,
      tenant   => $tenant,
    }
  }

  keystone_service { $service_name:
    ensure      => present,
    type        => 'data_processing',
    description => 'OpenStack Data Processing',
  }

  keystone_endpoint { "${region}/${service_name}":
    ensure       => present,
    public_url   => "http://${public_address}:${sahara_port}/v1.1/%(tenant_id)s",
    internal_url => "http://${internal_address}:${sahara_port}/v1.1/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${sahara_port}/v1.1/%(tenant_id)s",
  }

  if !defined(Keystone_user_role["${auth_name}@${tenant}"]) {
    keystone_user_role { "${auth_name}@${tenant}":
      ensure  => present,
      roles   => 'admin',
    }
  }

}


