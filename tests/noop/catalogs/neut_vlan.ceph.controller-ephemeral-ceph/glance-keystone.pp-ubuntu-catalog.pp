class { 'Glance::Keystone::Auth':
  admin_url           => 'http://10.122.12.2:9292',
  auth_name           => 'glance',
  configure_endpoint  => 'true',
  configure_user      => 'true',
  configure_user_role => 'true',
  email               => 'glance@localhost',
  internal_url        => 'http://10.122.12.2:9292',
  name                => 'Glance::Keystone::Auth',
  password            => 'J3jcjTzv',
  public_url          => 'https://public.fuel.local:9292',
  region              => 'RegionOne',
  service_description => 'OpenStack Image Service',
  service_name        => 'glance',
  service_type        => 'image',
  tenant              => 'services',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

keystone::resource::service_identity { 'glance':
  admin_url             => 'http://10.122.12.2:9292',
  auth_name             => 'glance',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'glance@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://10.122.12.2:9292',
  name                  => 'glance',
  password              => 'J3jcjTzv',
  public_url            => 'https://public.fuel.local:9292',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'OpenStack Image Service',
  service_name          => 'glance',
  service_type          => 'image',
  tenant                => 'services',
}

keystone_endpoint { 'RegionOne/glance':
  ensure       => 'present',
  admin_url    => 'http://10.122.12.2:9292',
  internal_url => 'http://10.122.12.2:9292',
  name         => 'RegionOne/glance',
  public_url   => 'https://public.fuel.local:9292',
}

keystone_service { 'glance':
  ensure      => 'present',
  description => 'OpenStack Image Service',
  name        => 'glance',
  type        => 'image',
}

keystone_user { 'glance':
  ensure                => 'present',
  email                 => 'glance@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'glance',
  password              => 'J3jcjTzv',
  tenant                => 'services',
}

keystone_user_role { 'glance@services':
  ensure => 'present',
  name   => 'glance@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

