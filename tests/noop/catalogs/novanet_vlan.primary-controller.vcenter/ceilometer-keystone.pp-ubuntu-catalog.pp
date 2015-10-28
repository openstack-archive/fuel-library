class { 'Ceilometer::Keystone::Auth':
  admin_url           => 'http://172.16.1.2:8777',
  auth_name           => 'ceilometer',
  configure_endpoint  => 'true',
  configure_user      => 'true',
  configure_user_role => 'true',
  email               => 'ceilometer@localhost',
  internal_url        => 'http://172.16.1.2:8777',
  name                => 'Ceilometer::Keystone::Auth',
  password            => 'rM79wR8O',
  public_url          => 'https://public.fuel.local:8777',
  region              => 'RegionOne',
  service_description => 'Openstack Metering Service',
  service_name        => 'ceilometer',
  service_type        => 'metering',
  tenant              => 'services',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

keystone::resource::service_identity { 'ceilometer':
  admin_url             => 'http://172.16.1.2:8777',
  auth_name             => 'ceilometer',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'ceilometer@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://172.16.1.2:8777',
  name                  => 'ceilometer',
  password              => 'rM79wR8O',
  public_url            => 'https://public.fuel.local:8777',
  region                => 'RegionOne',
  roles                 => ['admin', 'ResellerAdmin'],
  service_description   => 'Openstack Metering Service',
  service_name          => 'ceilometer',
  service_type          => 'metering',
  tenant                => 'services',
}

keystone_endpoint { 'RegionOne/ceilometer':
  ensure       => 'present',
  admin_url    => 'http://172.16.1.2:8777',
  internal_url => 'http://172.16.1.2:8777',
  name         => 'RegionOne/ceilometer',
  public_url   => 'https://public.fuel.local:8777',
}

keystone_role { 'ResellerAdmin':
  ensure => 'present',
  before => 'Keystone_user_role[ceilometer@services]',
  name   => 'ResellerAdmin',
}

keystone_service { 'ceilometer':
  ensure      => 'present',
  description => 'Openstack Metering Service',
  name        => 'ceilometer',
  type        => 'metering',
}

keystone_user { 'ceilometer':
  ensure                => 'present',
  email                 => 'ceilometer@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'ceilometer',
  password              => 'rM79wR8O',
  tenant                => 'services',
}

keystone_user_role { 'ceilometer@services':
  ensure => 'present',
  name   => 'ceilometer@services',
  roles  => ['admin', 'ResellerAdmin'],
}

stage { 'main':
  name => 'main',
}

