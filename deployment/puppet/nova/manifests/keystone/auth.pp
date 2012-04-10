class nova::keystone::auth(
  $auth_name    = 'nova',
  $password     = 'nova_password',
  $service      = 'compute',
  $address      = '127.0.0.1',
  $compute_port = '8774',
  $volume_port  = '8776',
  $ec2_port     = '8773',
  $version      = 'v1.1'
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
    ensure       => present,
    type        => 'compute',
    description => "Openstack Compute Service",
  }
  keystone_endpoint { $auth_name:
    ensure       => present,
    region       => 'RegionOne',
    public_url   => "http://${address}:${compute_port}/${version}/%(tenant_id)s",
    admin_url    => "http://${address}:${compute_port}/${version}/%(tenant_id)s",
    internal_url => "http://${address}:${compute_port}/${version}/%(tenant_id)s",
  }

  keystone_service { "${auth_name}_volume":
    ensure      => present,
    type        => 'volume',
    description => 'Volume Service',
  }
  keystone_endpoint { "${auth_name}_volume":
    ensure       => present,
    region       => 'RegionOne',
    public_url   => "http://${address}:${volume_port}/${version}/%(tenant_id)s",
    admin_url    => "http://${address}:${volume_port}/${version}/%(tenant_id)s",
    internal_url => "http://${address}:${volume_port}/${version}/%(tenant_id)s",
  }

  keystone_service { "${auth_name}_ec2":
    ensure      => present,
    type        => 'ec2',
    description => 'EC2 service',
  }
  keystone_endpoint { "${auth_name}_ec2":
    ensure       => present,
    region       => 'RegionOne',
    public_url   => "http://${address}:${ec2_port}/services/Cloud",
    admin_url    => "http://${address}:${ec2_port}/services/Admin",
    internal_url => "http://${address}:${ec2_port}/services/Cloud",
  }

}
