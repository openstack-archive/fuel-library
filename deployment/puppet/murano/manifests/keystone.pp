class murano::keystone (
  $user             = 'murano',
  $password         = 'swordfish',
  $tenant           = 'services',
  $email            = 'murano@localhost',
  $public_address   = '127.0.0.1',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $region           = 'RegionOne',
  $murano_api_port  = '8082',
) {

  keystone_user { $user:
    ensure      => present,
    enabled     => true,
    tenant      => $tenant,
    email       => $email,
    password    => $password,
  }

  keystone_user_role { "${user}@${tenant}":
    roles  => 'admin',
    ensure => present,
  }

  keystone_service { $user:
    ensure      => present,
    type        => 'application_catalog',
    description => 'Application Catalog for OpenStack',
  }

  keystone_endpoint { $user:
    ensure       => present,
    region       => $region,
    public_url   => "http://${public_address}:${murano_api_port}/v1/%(tenant_id)s",
    internal_url => "http://${internal_address}:${murano_api_port}/v1/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${murano_api_port}/v1/%(tenant_id)s",
  }

}
