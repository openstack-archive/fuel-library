class glance::keystone::auth(
  $auth_name = 'glance',
  $password  = 'glance_password',
  $service   = 'image',
  $address   = '127.0.0.1',
  $port      = '9292'
) {

  Class['keystone::roles::admin'] -> Class['glance::keystone::auth']

  keystone_user { $auth_name:
    ensure   => present, 
    password => $password,
  }
  keystone_user_role { "${auth_name}@service":
    roles   => 'admin',
    require => Keystone_user[$auth_name]
  }
  keystone_service { $auth_name:
    type        => 'image',
    description => "Openstack Image Service",
  }
  keystone_endpoint { $auth_name:
    region       => 'RegionOne',
    public_url   => "http://${address}:${port}/v1",
    admin_url    => "http://${address}:${port}/v1",
    internal_url => "http://${address}:${port}/v1",
    require      => Keystone_service[$auth_name]
  } 

}
