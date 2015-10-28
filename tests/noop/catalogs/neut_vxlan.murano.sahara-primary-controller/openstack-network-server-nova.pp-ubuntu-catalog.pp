class { 'Nova::Network::Neutron':
  dhcp_domain                     => 'novalocal',
  firewall_driver                 => 'nova.virt.firewall.NoopFirewallDriver',
  name                            => 'Nova::Network::Neutron',
  network_api_class               => 'nova.network.neutronv2.api.API',
  neutron_admin_auth_url          => 'http://192.168.0.2:35357/v2.0',
  neutron_admin_password          => 'oT56DSZF',
  neutron_admin_tenant_name       => 'services',
  neutron_admin_username          => 'neutron',
  neutron_auth_strategy           => 'keystone',
  neutron_default_tenant_id       => 'default',
  neutron_extension_sync_interval => '600',
  neutron_ovs_bridge              => 'br-int',
  neutron_region_name             => 'RegionOne',
  neutron_url                     => 'http://192.168.0.2:9696',
  neutron_url_timeout             => '30',
  security_group_api              => 'neutron',
  vif_plugging_is_fatal           => 'true',
  vif_plugging_timeout            => '300',
}

class { 'Nova::Params':
  name => 'Nova::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

nova_config { 'DEFAULT/default_floating_pool':
  name   => 'DEFAULT/default_floating_pool',
  notify => 'Service[nova-api]',
  value  => 'net04_ext',
}

nova_config { 'DEFAULT/dhcp_domain':
  name   => 'DEFAULT/dhcp_domain',
  notify => 'Service[nova-api]',
  value  => 'novalocal',
}

nova_config { 'DEFAULT/firewall_driver':
  name   => 'DEFAULT/firewall_driver',
  notify => 'Service[nova-api]',
  value  => 'nova.virt.firewall.NoopFirewallDriver',
}

nova_config { 'DEFAULT/network_api_class':
  name   => 'DEFAULT/network_api_class',
  notify => 'Service[nova-api]',
  value  => 'nova.network.neutronv2.api.API',
}

nova_config { 'DEFAULT/security_group_api':
  name   => 'DEFAULT/security_group_api',
  notify => 'Service[nova-api]',
  value  => 'neutron',
}

nova_config { 'DEFAULT/vif_plugging_is_fatal':
  name   => 'DEFAULT/vif_plugging_is_fatal',
  notify => 'Service[nova-api]',
  value  => 'true',
}

nova_config { 'DEFAULT/vif_plugging_timeout':
  name   => 'DEFAULT/vif_plugging_timeout',
  notify => 'Service[nova-api]',
  value  => '300',
}

nova_config { 'neutron/admin_auth_url':
  name   => 'neutron/admin_auth_url',
  notify => 'Service[nova-api]',
  value  => 'http://192.168.0.2:35357/v2.0',
}

nova_config { 'neutron/admin_password':
  name   => 'neutron/admin_password',
  notify => 'Service[nova-api]',
  secret => 'true',
  value  => 'oT56DSZF',
}

nova_config { 'neutron/admin_tenant_name':
  name   => 'neutron/admin_tenant_name',
  notify => 'Service[nova-api]',
  value  => 'services',
}

nova_config { 'neutron/admin_username':
  name   => 'neutron/admin_username',
  notify => 'Service[nova-api]',
  value  => 'neutron',
}

nova_config { 'neutron/auth_strategy':
  name   => 'neutron/auth_strategy',
  notify => 'Service[nova-api]',
  value  => 'keystone',
}

nova_config { 'neutron/ca_certificates_file':
  ensure => 'absent',
  name   => 'neutron/ca_certificates_file',
  notify => 'Service[nova-api]',
}

nova_config { 'neutron/default_tenant_id':
  name   => 'neutron/default_tenant_id',
  notify => 'Service[nova-api]',
  value  => 'default',
}

nova_config { 'neutron/extension_sync_interval':
  name   => 'neutron/extension_sync_interval',
  notify => 'Service[nova-api]',
  value  => '600',
}

nova_config { 'neutron/ovs_bridge':
  name   => 'neutron/ovs_bridge',
  notify => 'Service[nova-api]',
  value  => 'br-int',
}

nova_config { 'neutron/region_name':
  name   => 'neutron/region_name',
  notify => 'Service[nova-api]',
  value  => 'RegionOne',
}

nova_config { 'neutron/url':
  name   => 'neutron/url',
  notify => 'Service[nova-api]',
  value  => 'http://192.168.0.2:9696',
}

nova_config { 'neutron/url_timeout':
  name   => 'neutron/url_timeout',
  notify => 'Service[nova-api]',
  value  => '30',
}

service { 'nova-api':
  ensure => 'running',
  name   => 'nova-api',
}

stage { 'main':
  name => 'main',
}

