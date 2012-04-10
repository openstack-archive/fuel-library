class nova::keystone::auth(
  $auth_name = 'nova',
  $password  = 'nova_password',
  $service   = 'compute',
  $address   = '127.0.0.1',
  $port      = '8774',
  $version   = 'v1.1'
) {

  Class['keystone::roles::admin'] -> Class['nova::keystone::auth']

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
  }
  keystone_user_role { "${auth_name}@services":
    roles   => 'admin',
    require => Keystone_user[$auth_name]
  }
  keystone_service { $auth_name:
    type        => 'compute',
    description => "Openstack Compute Service",
  }
  keystone_endpoint { $auth_name:
    ensure       => present,
    public_url   => "http://${address}:${port}/${version}/%(tenant_id)s",
    admin_url    => "http://${address}:${port}/${version}/%(tenant_id)s",
    internal_url => "http://${address}:${port}/${version}/%(tenant_id)s",
  }

}
