class neutron::keystone::auth (
  $neutron_config     = {},
  $configure_endpoint = true,
  $service_type       = 'network',
  $public_address     = '127.0.0.1',
  $admin_address      = '127.0.0.1',
  $internal_address   = '127.0.0.1',
) {

  keystone_user { $neutron_config['keystone']['admin_user']:
    ensure   => present,
    password => $neutron_config['keystone']['admin_password'],
    email    => $neutron_config['keystone']['admin_email'],
    tenant   => $neutron_config['keystone']['admin_tenant_name'],
  }
  keystone_user_role { "${neutron_config['keystone']['admin_user']}@services":
    ensure  => present,
    roles   => 'admin',
  }

  Keystone_user_role["${neutron_config['keystone']['admin_user']}@services"] ~> Service <| title == 'neutron-server' |>

  keystone_service { $neutron_config['keystone']['admin_user']:
    ensure      => present,
    type        => $service_type,
    description => 'Neutron Networking Service',
  }

  if $configure_endpoint {
    # keystone_endpoint { "${region}/$neutron_config['keystone']['admin_user']":
    keystone_endpoint { $neutron_config['keystone']['admin_user']:
      ensure       => present,
      region       => $neutron_config['keystone']['auth_region'],
      public_url   => "http://${public_address}:${neutron_config['server']['bind_port']}",
      admin_url    => "http://${admin_address}:${$neutron_config['server']['bind_port']}",
      internal_url => "http://${internal_address}:${$neutron_config['server']['bind_port']}",
    }
  }
}
