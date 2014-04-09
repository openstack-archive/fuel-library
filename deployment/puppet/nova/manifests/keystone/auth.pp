#
class nova::keystone::auth(
  $password,
  $auth_name              = 'nova',
  $public_address         = '127.0.0.1',
  $admin_address          = '127.0.0.1',
  $internal_address       = '127.0.0.1',
  $compute_port           = '8774',
  $ec2_port               = '8773',
  $compute_version        = 'v2',
  $region                 = 'RegionOne',
  $tenant                 = 'services',
  $email                  = 'nova@localhost',
  $configure_ec2_endpoint = true,
  $cinder                 = undef,
  $public_protocol        = 'http'
) {

  if $cinder != undef {
    warning('cinder parameter is deprecated and has no effect.')
  }

  Keystone_endpoint["${region}/${auth_name}"] ~> Service <| name == 'nova-api' |>

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
    description => 'Openstack Compute Service',
  }
  keystone_endpoint { "${region}/${auth_name}":
    ensure       => present,
    public_url   => "${public_protocol}://${public_address}:${compute_port}/${compute_version}/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${compute_port}/${compute_version}/%(tenant_id)s",
    internal_url => "http://${internal_address}:${compute_port}/${compute_version}/%(tenant_id)s",
  }

  if $configure_ec2_endpoint {
    keystone_service { "${auth_name}_ec2":
      ensure      => present,
      type        => 'ec2',
      description => 'EC2 Service',
    }
    keystone_endpoint { "${region}/${auth_name}_ec2":
      ensure       => present,
      public_url   => "${public_protocol}://${public_address}:${ec2_port}/services/Cloud",
      admin_url    => "http://${admin_address}:${ec2_port}/services/Admin",
      internal_url => "http://${internal_address}:${ec2_port}/services/Cloud",
    }
  }
}
