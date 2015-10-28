class { 'Murano::Keystone::Auth':
  admin_url           => 'http://192.168.0.2:8082',
  auth_name           => 'murano',
  configure_endpoint  => 'true',
  email               => 'murano@localhost',
  internal_url        => 'http://192.168.0.2:8082',
  name                => 'Murano::Keystone::Auth',
  password            => 'xP8WtHQw',
  public_url          => 'https://public.fuel.local:8082',
  region              => 'RegionOne',
  service_description => 'Murano Application Catalog',
  service_type        => 'application_catalog',
  tenant              => 'services',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

keystone::resource::service_identity { 'murano':
  admin_url             => 'http://192.168.0.2:8082',
  auth_name             => 'murano',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'murano@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.2:8082',
  name                  => 'murano',
  password              => 'xP8WtHQw',
  public_url            => 'https://public.fuel.local:8082',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Murano Application Catalog',
  service_type          => 'application_catalog',
  tenant                => 'services',
}

keystone_endpoint { 'RegionOne/murano':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.2:8082',
  internal_url => 'http://192.168.0.2:8082',
  name         => 'RegionOne/murano',
  public_url   => 'https://public.fuel.local:8082',
}

keystone_service { 'murano':
  ensure      => 'present',
  description => 'Murano Application Catalog',
  name        => 'murano',
  type        => 'application_catalog',
}

keystone_user { 'murano':
  ensure                => 'present',
  email                 => 'murano@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'murano',
  password              => 'xP8WtHQw',
  tenant                => 'services',
}

keystone_user_role { 'murano@services':
  ensure => 'present',
  name   => 'murano@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

