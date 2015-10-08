notice('MODULAR: heat/keystone.pp')

$heat_hash         = hiera_hash('heat', {})
$public_vip        = hiera('public_vip')
$admin_address     = hiera('management_vip')
$region            = pick($heat_hash['region'], hiera('region', 'RegionOne'))
$public_ssl_hash   = hiera('public_ssl')
$public_address    = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol   = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}

$password            = $heat_hash['user_password']
$auth_name           = pick($heat_hash['auth_name'], 'heat')
$configure_endpoint  = pick($heat_hash['configure_endpoint'], true)
$configure_user      = pick($heat_hash['configure_user'], true)
$configure_user_role = pick($heat_hash['configure_user_role'], true)
$service_name        = pick($heat_hash['service_name'], 'heat')
$tenant              = pick($heat_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

$public_url          = "${public_protocol}://${public_address}:8004/v1/%(tenant_id)s"
$admin_url           = "http://${admin_address}:8004/v1/%(tenant_id)s"
$public_url_cfn      = "${public_protocol}://${public_address}:8000/v1"
$admin_url_cfn       = "http://${admin_address}:8000/v1"



class { '::heat::keystone::auth' :
  password               => $password,
  auth_name              => $auth_name,
  region                 => $region,
  tenant                 => $keystone_tenant,
  email                  => "${auth_name}@localhost",
  configure_endpoint     => true,
  trusts_delegated_roles => $trusts_delegated_roles,
  public_url             => $public_url,
  internal_url           => $admin_url,
  admin_url              => $admin_url,
}

class { '::heat::keystone::auth_cfn' :
  password           => $password,
  auth_name          => "${auth_name}-cfn",
  service_type       => 'cloudformation',
  region             => $region,
  tenant             => $keystone_tenant,
  email              => "${auth_name}-cfn@localhost",
  configure_endpoint => true,
  public_url         => $public_url_cfn,
  internal_url       => $admin_url_cfn,
  admin_url          => $admin_url_cfn,
}
