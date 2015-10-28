class { 'Settings':
  name => 'Settings',
}

class { 'Swift::Keystone::Auth':
  admin_url              => 'http://192.168.0.7:8080/v1/AUTH_%(tenant_id)s',
  admin_url_s3           => 'http://192.168.0.7:8080',
  auth_name              => 'swift',
  configure_endpoint     => 'true',
  configure_s3_endpoint  => 'true',
  email                  => 'swift@localhost',
  internal_url           => 'http://192.168.0.7:8080/v1/AUTH_%(tenant_id)s',
  internal_url_s3        => 'http://192.168.0.7:8080',
  name                   => 'Swift::Keystone::Auth',
  operator_roles         => ['admin', 'SwiftOperator'],
  password               => 'bpFT3TKn',
  public_url             => 'https://public.fuel.local:8080/v1/AUTH_%(tenant_id)s',
  public_url_s3          => 'https://public.fuel.local:8080',
  region                 => 'RegionOne',
  service_description    => 'Openstack Object-Store Service',
  service_description_s3 => 'Openstack S3 Service',
  service_name           => 'swift',
  tenant                 => 'services',
}

class { 'main':
  name => 'main',
}

keystone::resource::service_identity { 'swift':
  admin_url             => 'http://192.168.0.7:8080/v1/AUTH_%(tenant_id)s',
  auth_name             => 'swift',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'swift@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.7:8080/v1/AUTH_%(tenant_id)s',
  name                  => 'swift',
  password              => 'bpFT3TKn',
  public_url            => 'https://public.fuel.local:8080/v1/AUTH_%(tenant_id)s',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Openstack Object-Store Service',
  service_name          => 'swift',
  service_type          => 'object-store',
  tenant                => 'services',
}

keystone::resource::service_identity { 'swift_s3':
  admin_url             => 'http://192.168.0.7:8080',
  auth_name             => 'swift_s3',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'false',
  configure_user_role   => 'false',
  email                 => 'swift_s3@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.7:8080',
  name                  => 'swift_s3',
  password              => 'false',
  public_url            => 'https://public.fuel.local:8080',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Openstack S3 Service',
  service_name          => 'swift_s3',
  service_type          => 's3',
  tenant                => 'services',
}

keystone_endpoint { 'RegionOne/swift':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.7:8080/v1/AUTH_%(tenant_id)s',
  internal_url => 'http://192.168.0.7:8080/v1/AUTH_%(tenant_id)s',
  name         => 'RegionOne/swift',
  public_url   => 'https://public.fuel.local:8080/v1/AUTH_%(tenant_id)s',
}

keystone_endpoint { 'RegionOne/swift_s3':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.7:8080',
  internal_url => 'http://192.168.0.7:8080',
  name         => 'RegionOne/swift_s3',
  public_url   => 'https://public.fuel.local:8080',
}

keystone_role { 'SwiftOperator':
  ensure => 'present',
  name   => 'SwiftOperator',
}

keystone_role { 'admin':
  ensure => 'present',
  name   => 'admin',
}

keystone_service { 'swift':
  ensure      => 'present',
  description => 'Openstack Object-Store Service',
  name        => 'swift',
  type        => 'object-store',
}

keystone_service { 'swift_s3':
  ensure      => 'present',
  description => 'Openstack S3 Service',
  name        => 'swift_s3',
  type        => 's3',
}

keystone_user { 'swift':
  ensure                => 'present',
  before                => 'Keystone_user_role[swift@services]',
  email                 => 'swift@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'swift',
  password              => 'bpFT3TKn',
  tenant                => 'services',
}

keystone_user_role { 'swift@services':
  ensure => 'present',
  name   => 'swift@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

