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
  provider_network_type     => 'vlan',
  provider_physical_network => 'physnet2',
  provider_segmentation_id  => '1000',
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
  cidr            => '10.122.13.0/24',
  dns_nameservers => ['8.8.4.4', '8.8.8.8'],
  enable_dhcp     => 'true',
  gateway_ip      => '10.122.13.1',
  name            => 'net04__subnet',
  network_name    => 'net04',
  tenant_name     => 'admin',
}

neutron_subnet { 'net04_ext__subnet':
  ensure           => 'present',
  allocation_pools => 'start=10.122.11.130,end=10.122.11.254',
  cidr             => '10.122.11.0/24',
  enable_dhcp      => 'false',
  gateway_ip       => '10.122.11.1',
  name             => 'net04_ext__subnet',
  network_name     => 'net04_ext',
  tenant_name      => 'admin',
}

stage { 'main':
  name => 'main',
}

