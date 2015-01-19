class murano::keystone (
  $user             = 'murano',
  $password         = 'swordfish',
  $tenant           = 'services',
  $email            = 'murano@localhost',
  $service_name     = 'murano',
  $public_address   = '127.0.0.1',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $region           = 'RegionOne',
  $murano_api_port  = '8082',
  $allow_add_user   = true,
) {

  if ($allow_add_user !=false) {
    keystone_user { $user:
      ensure      => present,
      enabled     => true,
      tenant      => $tenant,
      email       => $email,
      password    => $password,
    }
  }

  if !defined(Keystone_user_role["${user}@${tenant}"]) {
    keystone_user_role { "${user}@${tenant}":
      roles  => 'admin',
      ensure => present,
    }
  }


  keystone_service { $service_name:
    ensure      => present,
    type        => 'application_catalog',
    description => 'Application Catalog for OpenStack',
  }

  keystone_endpoint { "${region}/${service_name}":
    ensure       => present,
    public_url   => "http://${public_address}:${murano_api_port}/v1/%(tenant_id)s",
    internal_url => "http://${internal_address}:${murano_api_port}/v1/%(tenant_id)s",
    admin_url    => "http://${admin_address}:${murano_api_port}/v1/%(tenant_id)s",
  }

}
