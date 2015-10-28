class { 'Heat::Keystone::Auth':
  admin_url                   => 'http://192.168.0.2:8004/v1/%(tenant_id)s',
  auth_name                   => 'heat',
  configure_delegated_roles   => 'false',
  configure_endpoint          => 'true',
  configure_service           => 'true',
  configure_user              => 'true',
  configure_user_role         => 'true',
  email                       => 'heat@localhost',
  heat_stack_user_role        => 'heat_stack_user',
  internal_url                => 'http://192.168.0.2:8004/v1/%(tenant_id)s',
  manage_heat_stack_user_role => 'true',
  name                        => 'Heat::Keystone::Auth',
  password                    => 'CxKs9UObDHZOgw20Gv3kwtGT',
  public_url                  => 'https://public.fuel.local:8004/v1/%(tenant_id)s',
  region                      => 'RegionOne',
  service_description         => 'Openstack Orchestration Service',
  service_type                => 'orchestration',
  tenant                      => 'services',
  trusts_delegated_roles      => 'heat_stack_owner',
}

class { 'Heat::Keystone::Auth_cfn':
  admin_url           => 'http://192.168.0.2:8000/v1',
  auth_name           => 'heat-cfn',
  configure_endpoint  => 'true',
  configure_service   => 'true',
  configure_user      => 'true',
  configure_user_role => 'true',
  email               => 'heat-cfn@localhost',
  internal_url        => 'http://192.168.0.2:8000/v1',
  name                => 'Heat::Keystone::Auth_cfn',
  password            => 'CxKs9UObDHZOgw20Gv3kwtGT',
  public_url          => 'https://public.fuel.local:8000/v1',
  region              => 'RegionOne',
  service_type        => 'cloudformation',
  tenant              => 'services',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

keystone::resource::service_identity { 'heat-cfn':
  admin_url             => 'http://192.168.0.2:8000/v1',
  auth_name             => 'heat-cfn',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'heat-cfn@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.2:8000/v1',
  name                  => 'heat-cfn',
  password              => 'CxKs9UObDHZOgw20Gv3kwtGT',
  public_url            => 'https://public.fuel.local:8000/v1',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Openstack Cloudformation Service',
  service_name          => 'heat-cfn',
  service_type          => 'cloudformation',
  tenant                => 'services',
}

keystone::resource::service_identity { 'heat':
  admin_url             => 'http://192.168.0.2:8004/v1/%(tenant_id)s',
  auth_name             => 'heat',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'heat@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://192.168.0.2:8004/v1/%(tenant_id)s',
  name                  => 'heat',
  password              => 'CxKs9UObDHZOgw20Gv3kwtGT',
  public_url            => 'https://public.fuel.local:8004/v1/%(tenant_id)s',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'Openstack Orchestration Service',
  service_name          => 'heat',
  service_type          => 'orchestration',
  tenant                => 'services',
}

keystone_endpoint { 'RegionOne/heat-cfn':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.2:8000/v1',
  internal_url => 'http://192.168.0.2:8000/v1',
  name         => 'RegionOne/heat-cfn',
  public_url   => 'https://public.fuel.local:8000/v1',
}

keystone_endpoint { 'RegionOne/heat':
  ensure       => 'present',
  admin_url    => 'http://192.168.0.2:8004/v1/%(tenant_id)s',
  internal_url => 'http://192.168.0.2:8004/v1/%(tenant_id)s',
  name         => 'RegionOne/heat',
  public_url   => 'https://public.fuel.local:8004/v1/%(tenant_id)s',
}

keystone_role { 'heat_stack_user':
  ensure => 'present',
  name   => 'heat_stack_user',
}

keystone_service { 'heat-cfn':
  ensure      => 'present',
  description => 'Openstack Cloudformation Service',
  name        => 'heat-cfn',
  type        => 'cloudformation',
}

keystone_service { 'heat':
  ensure      => 'present',
  description => 'Openstack Orchestration Service',
  name        => 'heat',
  type        => 'orchestration',
}

keystone_user { 'heat-cfn':
  ensure                => 'present',
  email                 => 'heat-cfn@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'heat-cfn',
  password              => 'CxKs9UObDHZOgw20Gv3kwtGT',
  tenant                => 'services',
}

keystone_user { 'heat':
  ensure                => 'present',
  email                 => 'heat@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'heat',
  password              => 'CxKs9UObDHZOgw20Gv3kwtGT',
  tenant                => 'services',
}

keystone_user_role { 'heat-cfn@services':
  ensure => 'present',
  name   => 'heat-cfn@services',
  roles  => 'admin',
}

keystone_user_role { 'heat@services':
  ensure => 'present',
  name   => 'heat@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

