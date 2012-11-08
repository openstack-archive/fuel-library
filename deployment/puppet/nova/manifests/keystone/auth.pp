class nova::keystone::auth(
  $password,
  $auth_name        = 'nova',
  $public_address   = '127.0.0.1',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $compute_port     = '8774',
  $volume_port      = '8776',
  $ec2_port         = '8773',
  $compute_version  = 'v2',
  $volume_version   = 'v1',
  $cinder           = false,
  $region           = 'RegionOne',
  $tenant           = 'services',
  $email            = 'nova@localhost'
) {

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }
  keystone_user_role { "${auth_name}@${tenant}":
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
    public_url   => "http://${public_address}:${compute_port}/${compute_version}/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${compute_port}/${compute_version}/%(tenant_id)s",
    internal_url => "http://${internal_address}:${compute_port}/${compute_version}/%(tenant_id)s",
  }

  if !($cinder)
  {
  keystone_service { "${auth_name}_volume":
    ensure      => present,
    type        => 'volume',
    description => 'Volume Service',
  }
  keystone_endpoint { "${auth_name}_volume":
    ensure       => present,
    region       => $region,
    public_url   => "http://${public_address}:${volume_port}/${volume_version}/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${volume_port}/${volume_version}/%(tenant_id)s",
    internal_url => "http://${internal_address}:${volume_port}/${volume_version}/%(tenant_id)s",
  }
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
