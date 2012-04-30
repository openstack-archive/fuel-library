class nova::keystone::auth(
  $auth_name        = 'nova',
  $password         = 'nova_password',
  $public_address   = '127.0.0.1',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $compute_port     = '8774',
  $volume_port      = '8776',
  $ec2_port         = '8773',
  $version          = 'v1.1',
  $region           = 'RegionOne'
) {

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
    type        => 'compute',
    description => "Openstack Compute Service",
  }
  keystone_endpoint { $auth_name:
    ensure       => present,
    region       => $region,
    public_url   => "http://${public_address}:${compute_port}/${version}/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${compute_port}/${version}/%(tenant_id)s",
    internal_url => "http://${internal_address}:${compute_port}/${version}/%(tenant_id)s",
  }

  keystone_service { "${auth_name}_volume":
    ensure      => present,
    type        => 'volume',
    description => 'Volume Service',
  }
  keystone_endpoint { "${auth_name}_volume":
    ensure       => present,
    region       => $region,
    public_url   => "http://${public_address}:${volume_port}/${version}/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${volume_port}/${version}/%(tenant_id)s",
    internal_url => "http://${internal_address}:${volume_port}/${version}/%(tenant_id)s",
  }

  keystone_service { "${auth_name}_ec2":
    ensure      => present,
    type        => 'ec2',
    description => 'EC2 Service',
  }
  keystone_endpoint { "${auth_name}_ec2":
    ensure       => present,
    region       => $region,
    public_url   => "http://${public_address}:${ec2_port}/services/Cloud",
    admin_url    => "http://${admin_address}:${ec2_port}/services/Admin",
    internal_url => "http://${internal_address}:${ec2_port}/services/Cloud",
  }

}
