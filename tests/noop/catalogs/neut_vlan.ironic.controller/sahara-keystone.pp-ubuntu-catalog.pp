class { 'Sahara::Keystone::Auth':
  admin_url           => 'http://192.168.0.2:8386/v1.1/%(tenant_id)s',
  auth_name           => 'sahara',
  configure_endpoint  => 'true',
  email               => 'sahara@localhost',
  internal_url        => 'http://192.168.0.2:8386/v1.1/%(tenant_id)s',
  name                => 'Sahara::Keystone::Auth',
  password            => '1Zhv0E5kprZOcoh0JFlIv4vf',
  public_url          => 'https://public.fuel.local:8386/v1.1/%(tenant_id)s',
  region              => 'RegionOne',
  service_description => 'Sahara Data Processing',
  service_name        => 'sahara',
  service_type        => 'data_processing',
  tenant              => 'services',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

keystone::resource::service_identity { 'sahara':
  admin_url             => 'http://192.168.0.2:8386/v1.1/%(tenant_id)s',
  auth_name             => 'sahara',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'sahara@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.2:8386/v1.1/%(tenant_id)s',
  name                  => 'sahara',
  password              => '1Zhv0E5kprZOcoh0JFlIv4vf',
  public_url            => 'https://public.fuel.local:8386/v1.1/%(tenant_id)s',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Sahara Data Processing',
  service_type          => 'data_processing',
  tenant                => 'services',
}

keystone_endpoint { 'RegionOne/sahara':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.2:8386/v1.1/%(tenant_id)s',
  internal_url => 'http://192.168.0.2:8386/v1.1/%(tenant_id)s',
  name         => 'RegionOne/sahara',
  public_url   => 'https://public.fuel.local:8386/v1.1/%(tenant_id)s',
}

keystone_service { 'sahara':
  ensure      => 'present',
  description => 'Sahara Data Processing',
  name        => 'sahara',
  type        => 'data_processing',
}

keystone_user { 'sahara':
  ensure                => 'present',
  email                 => 'sahara@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'sahara',
  password              => '1Zhv0E5kprZOcoh0JFlIv4vf',
  tenant                => 'services',
}

keystone_user_role { 'sahara@services':
  ensure => 'present',
  name   => 'sahara@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

