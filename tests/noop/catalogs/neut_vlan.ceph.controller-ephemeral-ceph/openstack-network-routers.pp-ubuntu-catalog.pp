class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

neutron_router { 'router04':
  ensure               => 'present',
  before               => 'Neutron_router_interface[router04:net04__subnet]',
  gateway_network_name => 'net04_ext',
  name                 => 'router04',
  tenant_name          => 'admin',
}

neutron_router_interface { 'router04:net04__subnet':
  ensure => 'present',
  name   => 'router04:net04__subnet',
}

stage { 'main':
  name => 'main',
}

