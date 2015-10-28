class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

neutron_network { 'net04':
  ensure                    => 'present',
  before                    => 'Neutron_subnet[net04__subnet]',
  name                      => 'net04',
  provider_network_type     => 'vxlan',
  provider_physical_network => 'false',
  provider_segmentation_id  => '2',
  router_external           => 'false',
  shared                    => 'false',
  tenant_name               => 'admin',
}

neutron_network { 'net04_ext':
  ensure                    => 'present',
  before                    => 'Neutron_subnet[net04_ext__subnet]',
  name                      => 'net04_ext',
  provider_network_type     => 'local',
  provider_physical_network => 'false',
  router_external           => 'true',
  shared                    => 'false',
  tenant_name               => 'admin',
}

neutron_subnet { 'net04__subnet':
  ensure          => 'present',
  cidr            => '192.168.111.0/24',
  dns_nameservers => ['8.8.4.4', '8.8.8.8'],
  enable_dhcp     => 'true',
  gateway_ip      => '192.168.111.1',
  name            => 'net04__subnet',
  network_name    => 'net04',
  tenant_name     => 'admin',
}

neutron_subnet { 'net04_ext__subnet':
  ensure           => 'present',
  allocation_pools => 'start=172.16.0.130,end=172.16.0.254',
  cidr             => '172.16.0.0/24',
  enable_dhcp      => 'false',
  gateway_ip       => '172.16.0.1',
  name             => 'net04_ext__subnet',
  network_name     => 'net04_ext',
  tenant_name      => 'admin',
}

stage { 'main':
  name => 'main',
}

