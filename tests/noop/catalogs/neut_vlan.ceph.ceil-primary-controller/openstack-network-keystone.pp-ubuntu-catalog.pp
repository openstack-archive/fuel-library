class { 'Neutron::Keystone::Auth':
  admin_url           => 'http://192.168.0.7:9696',
  auth_name           => 'neutron',
  configure_endpoint  => 'true',
  configure_user      => 'true',
  configure_user_role => 'true',
  email               => 'neutron@localhost',
  internal_url        => 'http://192.168.0.7:9696',
  name                => 'Neutron::Keystone::Auth',
  password            => 'XgdPodA7',
  public_url          => 'https://public.fuel.local:9696',
  region              => 'RegionOne',
  service_description => 'Neutron Networking Service',
  service_name        => 'neutron',
  service_type        => 'network',
  tenant              => 'services',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

keystone::resource::service_identity { 'neutron':
  admin_url             => 'http://192.168.0.7:9696',
  auth_name             => 'neutron',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'neutron@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.7:9696',
  name                  => 'neutron',
  password              => 'XgdPodA7',
  public_url            => 'https://public.fuel.local:9696',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Neutron Networking Service',
  service_name          => 'neutron',
  service_type          => 'network',
  tenant                => 'services',
}

keystone_endpoint { 'RegionOne/neutron':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.7:9696',
  internal_url => 'http://192.168.0.7:9696',
  name         => 'RegionOne/neutron',
  public_url   => 'https://public.fuel.local:9696',
}

keystone_service { 'neutron':
  ensure      => 'present',
  description => 'Neutron Networking Service',
  name        => 'neutron',
  type        => 'network',
}

keystone_user { 'neutron':
  ensure                => 'present',
  email                 => 'neutron@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'neutron',
  password              => 'XgdPodA7',
  tenant                => 'services',
}

keystone_user_role { 'neutron@services':
  ensure => 'present',
  name   => 'neutron@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

