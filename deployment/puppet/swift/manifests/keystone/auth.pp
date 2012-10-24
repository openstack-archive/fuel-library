class swift::keystone::auth(
  $auth_name = 'swift',
  $password  = 'swift_password',
  $internal_address   = '127.0.0.1',
  $admin_address = '127.0.0.1',
  $public_address = '127.0.0.1',
  $port      = '8080'
) {

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
  }
  keystone_user_role { "${auth_name}@services":
    ensure  => present,
    roles   => 'admin',
    require => Keystone_user[$auth_name]
  }

  keystone_service { $auth_name:
    ensure      => present,
    type        => 'object-store',
    description => 'Openstack Object-Store Service',
  }
  keystone_endpoint { $auth_name:
    ensure       => present,
    region       => 'RegionOne',
    public_url   => "http://${public_address}:${port}/v1/AUTH_%(tenant_id)s",
    admin_url    => "http://${admin_address}:${port}/",
    internal_url => "http://${internal_address}:${port}/v1/AUTH_%(tenant_id)s",
  }

  keystone_service { "${auth_name}_s3":
    ensure      => present,
    type        => 's3',
    description => 'Openstack S3 Service',
  }
  keystone_endpoint { "${auth_name}_s3":
    ensure       => present,
    region       => 'RegionOne',
    public_url   => "http://${public_address}:${port}",
    admin_url    => "http://${admin_address}:${port}",
    internal_url => "http://${internal_address}:${port}",
  }

}
