class sahara::keystone::auth (
  $password         = 'sahara',
  $auth_name        = 'sahara',
  $public_address   = '127.0.0.1',
  $public_protocol  = 'http',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $sahara_port      = '8386',
  $region           = 'RegionOne',
  $tenant           = 'services',
  $email            = 'sahara@localhost'
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
    description => 'OpenStack Data Processing',
  }

  keystone_endpoint { "$region/$auth_name":
    ensure       => present,
    public_url   => "${public_protocol}://${public_address}:${sahara_port}/v1.1/%(tenant_id)s",
    internal_url => "http://${internal_address}:${sahara_port}/v1.1/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${sahara_port}/v1.1/%(tenant_id)s",
  }

  keystone_user_role { "${auth_name}@${tenant}":
    ensure  => present,
    roles   => 'admin',
  }

}


