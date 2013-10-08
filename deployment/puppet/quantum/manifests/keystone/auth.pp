class quantum::keystone::auth (
  quantum_config      = {},
  $configure_endpoint = true,
  $service_type       = 'network',
  $public_address     = '127.0.0.1',
  $admin_address      = '127.0.0.1',
  $internal_address   = '127.0.0.1',
) {

  keystone_user { $quantum_config['keystone']['admin_user']:
    ensure   => present,
    password => $quantum_config['keystone']['admin_password'],
    email    => $quantum_config['keystone']['admin_email'],
    tenant   => $quantum_config['keystone']['admin_tenant_name'],
  }
  keystone_user_role { "${quantum_config['keystone']['admin_user']}@services":
    ensure  => present,
    roles   => 'admin',
  }

  Keystone_user_role["${quantum_config['keystone']['admin_user']}@services"] ~> Service <| name == 'quantum-server' |>

  keystone_service { $quantum_config['keystone']['admin_user']:
    ensure      => present,
    type        => $service_type,
    description => "Quantum Networking Service",
  }

  if $configure_endpoint {
    # keystone_endpoint { "${region}/$quantum_config['keystone']['admin_user']":
    keystone_endpoint { $quantum_config['keystone']['admin_user']:
      region       => $quantum_config['keystone']['auth_region'],
      ensure       => present,
      public_url   => "http://${public_address}:${quantum_config['server']['bind_port']}",
      admin_url    => "http://${admin_address}:${$quantum_config['server']['bind_port']}",
      internal_url => "http://${internal_address}:${$quantum_config['server']['bind_port']}",
    }
  }
}
