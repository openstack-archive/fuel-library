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
  allocation_pools => 'start=172.16.51.121,end=172.16.51.126',
  cidr             => '172.16.51.112/28',
  enable_dhcp      => 'false',
  gateway_ip       => '172.16.51.113',
  name             => 'net04_ext__subnet',
  network_name     => 'net04_ext',
  tenant_name      => 'admin',
}

stage { 'main':
  name => 'main',
}

