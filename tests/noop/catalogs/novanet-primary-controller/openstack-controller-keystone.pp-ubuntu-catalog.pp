class { 'Nova::Keystone::Auth':
  admin_url               => 'http://192.168.0.5:8774/v2/%(tenant_id)s',
  admin_url_v3            => 'http://192.168.0.5:8774/v3',
  auth_name               => 'nova',
  auth_name_v3            => 'novav3',
  configure_ec2_endpoint  => 'true',
  configure_endpoint      => 'true',
  configure_endpoint_v3   => 'true',
  configure_user          => 'true',
  configure_user_role     => 'true',
  ec2_admin_url           => 'http://192.168.0.5:8773/services/Admin',
  ec2_internal_url        => 'http://192.168.0.5:8773/services/Cloud',
  ec2_public_url          => 'https://public.fuel.local:8773/services/Cloud',
  email                   => 'nova@localhost',
  internal_url            => 'http://192.168.0.5:8774/v2/%(tenant_id)s',
  internal_url_v3         => 'http://192.168.0.5:8774/v3',
  name                    => 'Nova::Keystone::Auth',
  password                => 'UyrT2Ama',
  public_url              => 'https://public.fuel.local:8774/v2/%(tenant_id)s',
  public_url_v3           => 'https://public.fuel.local:8774/v3',
  region                  => 'RegionOne',
  service_description     => 'Openstack Compute Service',
  service_description_ec2 => 'EC2 Service',
  service_description_v3  => 'Openstack Compute Service v3',
  service_name            => 'nova',
  tenant                  => 'services',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

keystone::resource::service_identity { 'nova ec2 service, user nova_ec2':
  admin_url             => 'http://192.168.0.5:8773/services/Admin',
  auth_name             => 'nova_ec2',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'false',
  configure_user_role   => 'false',
  email                 => 'nova ec2 service, user nova_ec2@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.5:8773/services/Cloud',
  name                  => 'nova ec2 service, user nova_ec2',
  password              => 'false',
  public_url            => 'https://public.fuel.local:8773/services/Cloud',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'EC2 Service',
  service_name          => 'nova_ec2',
  service_type          => 'ec2',
  tenant                => 'services',
}

keystone::resource::service_identity { 'nova service, user nova':
  admin_url             => 'http://192.168.0.5:8774/v2/%(tenant_id)s',
  auth_name             => 'nova',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'nova@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.5:8774/v2/%(tenant_id)s',
  name                  => 'nova service, user nova',
  password              => 'UyrT2Ama',
  public_url            => 'https://public.fuel.local:8774/v2/%(tenant_id)s',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Openstack Compute Service',
  service_name          => 'nova',
  service_type          => 'compute',
  tenant                => 'services',
}

keystone::resource::service_identity { 'nova v3 service, user novav3':
  admin_url             => 'http://192.168.0.5:8774/v3',
  auth_name             => 'novav3',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'false',
  configure_user_role   => 'false',
  email                 => 'nova v3 service, user novav3@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.5:8774/v3',
  name                  => 'nova v3 service, user novav3',
  password              => 'false',
  public_url            => 'https://public.fuel.local:8774/v3',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Openstack Compute Service v3',
  service_name          => 'novav3',
  service_type          => 'computev3',
  tenant                => 'services',
}

keystone_endpoint { 'RegionOne/nova':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.5:8774/v2/%(tenant_id)s',
  internal_url => 'http://192.168.0.5:8774/v2/%(tenant_id)s',
  name         => 'RegionOne/nova',
  public_url   => 'https://public.fuel.local:8774/v2/%(tenant_id)s',
}

keystone_endpoint { 'RegionOne/nova_ec2':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.5:8773/services/Admin',
  internal_url => 'http://192.168.0.5:8773/services/Cloud',
  name         => 'RegionOne/nova_ec2',
  public_url   => 'https://public.fuel.local:8773/services/Cloud',
}

keystone_endpoint { 'RegionOne/novav3':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.5:8774/v3',
  internal_url => 'http://192.168.0.5:8774/v3',
  name         => 'RegionOne/novav3',
  public_url   => 'https://public.fuel.local:8774/v3',
}

keystone_service { 'nova':
  ensure      => 'present',
  description => 'Openstack Compute Service',
  name        => 'nova',
  type        => 'compute',
}

keystone_service { 'nova_ec2':
  ensure      => 'present',
  description => 'EC2 Service',
  name        => 'nova_ec2',
  type        => 'ec2',
}

keystone_service { 'novav3':
  ensure      => 'present',
  description => 'Openstack Compute Service v3',
  name        => 'novav3',
  type        => 'computev3',
}

keystone_user { 'nova':
  ensure                => 'present',
  email                 => 'nova@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'nova',
  password              => 'UyrT2Ama',
  tenant                => 'services',
}

keystone_user_role { 'nova@services':
  ensure => 'present',
  name   => 'nova@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

