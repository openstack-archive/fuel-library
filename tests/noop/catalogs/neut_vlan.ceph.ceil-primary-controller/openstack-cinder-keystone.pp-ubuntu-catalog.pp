class { 'Cinder::Keystone::Auth':
  admin_url              => 'http://192.168.0.7:8776/v1/%(tenant_id)s',
  admin_url_v2           => 'http://192.168.0.7:8776/v2/%(tenant_id)s',
  auth_name              => 'cinder',
  auth_name_v2           => 'cinderv2',
  configure_endpoint     => 'true',
  configure_endpoint_v2  => 'true',
  configure_user         => 'true',
  configure_user_role    => 'true',
  email                  => 'cinder@localhost',
  internal_url           => 'http://192.168.0.7:8776/v1/%(tenant_id)s',
  internal_url_v2        => 'http://192.168.0.7:8776/v2/%(tenant_id)s',
  name                   => 'Cinder::Keystone::Auth',
  password               => 'sJRfG0GP',
  public_url             => 'https://public.fuel.local:8776/v1/%(tenant_id)s',
  public_url_v2          => 'https://public.fuel.local:8776/v2/%(tenant_id)s',
  region                 => 'RegionOne',
  service_description    => 'Cinder Service',
  service_description_v2 => 'Cinder Service v2',
  service_name           => 'cinder',
  service_type           => 'volume',
  service_type_v2        => 'volumev2',
  tenant                 => 'services',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

keystone::resource::service_identity { 'cinder':
  admin_url             => 'http://192.168.0.7:8776/v1/%(tenant_id)s',
  auth_name             => 'cinder',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'cinder@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.7:8776/v1/%(tenant_id)s',
  name                  => 'cinder',
  password              => 'sJRfG0GP',
  public_url            => 'https://public.fuel.local:8776/v1/%(tenant_id)s',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Cinder Service',
  service_name          => 'cinder',
  service_type          => 'volume',
  tenant                => 'services',
}

keystone::resource::service_identity { 'cinderv2':
  admin_url             => 'http://192.168.0.7:8776/v2/%(tenant_id)s',
  auth_name             => 'cinderv2',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'false',
  configure_user_role   => 'false',
  email                 => 'cinderv2@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.7:8776/v2/%(tenant_id)s',
  name                  => 'cinderv2',
  password              => 'false',
  public_url            => 'https://public.fuel.local:8776/v2/%(tenant_id)s',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Cinder Service v2',
  service_name          => 'cinderv2',
  service_type          => 'volumev2',
  tenant                => 'services',
}

keystone_endpoint { 'RegionOne/cinder':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.7:8776/v1/%(tenant_id)s',
  internal_url => 'http://192.168.0.7:8776/v1/%(tenant_id)s',
  name         => 'RegionOne/cinder',
  public_url   => 'https://public.fuel.local:8776/v1/%(tenant_id)s',
}

keystone_endpoint { 'RegionOne/cinderv2':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.7:8776/v2/%(tenant_id)s',
  internal_url => 'http://192.168.0.7:8776/v2/%(tenant_id)s',
  name         => 'RegionOne/cinderv2',
  public_url   => 'https://public.fuel.local:8776/v2/%(tenant_id)s',
}

keystone_service { 'cinder':
  ensure      => 'present',
  description => 'Cinder Service',
  name        => 'cinder',
  type        => 'volume',
}

keystone_service { 'cinderv2':
  ensure      => 'present',
  description => 'Cinder Service v2',
  name        => 'cinderv2',
  type        => 'volumev2',
}

keystone_user { 'cinder':
  ensure                => 'present',
  email                 => 'cinder@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'cinder',
  password              => 'sJRfG0GP',
  tenant                => 'services',
}

keystone_user_role { 'cinder@services':
  ensure => 'present',
  name   => 'cinder@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

