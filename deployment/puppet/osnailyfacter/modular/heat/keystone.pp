notice('MODULAR: heat/keystone.pp')

$heat_hash        = hiera_hash('heat', {})
$public_address   = hiera('public_vip')
$internal_address = hiera('management_vip', $public_address)
$region           = pick($heat_hash['region'], 'RegionOne')
$public_ssl_hash  = hiera('public_ssl')

$password            = $heat_hash['user_password']
$auth_name           = pick($heat_hash['auth_name'], 'heat')
$configure_endpoint  = pick($heat_hash['configure_endpoint'], true)
$configure_user      = pick($heat_hash['configure_user'], true)
$configure_user_role = pick($heat_hash['configure_user_role'], true)
$service_name        = pick($heat_hash['service_name'], $auth_name)
$tenant              = pick($heat_hash['tenant'], 'services')

validate_string($public_address)
validate_string($password)

class { 'heat::keystone::auth' :
  password               => $password,
  auth_name              => $auth_name,
  public_address         => $public_address,
  admin_address          => $internal_address,
  internal_address       => $internal_address,
  port                   => '8004',
  version                => 'v1',
  region                 => $region,
  tenant                 => $keystone_tenant,
  email                  => "${keystone_user}@localhost",
  public_protocol        => $public_ssl ? {
    true    => 'https',
    default => 'http',
  },
  admin_protocol         => 'http',
  internal_protocol      => 'http',
  configure_endpoint     => true,
  trusts_delegated_roles => $trusts_delegated_roles,
}

class { 'heat::keystone::auth_cfn' :
  password           => $password,
  auth_name          => "${auth_name}-cfn",
  service_type       => 'cloudformation',
  public_address     => $public_address,
  admin_address      => $internal_address,
  internal_address   => $internal_address,
  port               => '8000',
  version            => 'v1',
  region             => $region,
  tenant             => $keystone_tenant,
  email              => "${keystone_user}-cfn@localhost",
  public_protocol    => $public_ssl ? {
    true    => 'https',
    default => 'http',
  },
  admin_protocol     => 'http',
  internal_protocol  => 'http',
  configure_endpoint => true,
}
