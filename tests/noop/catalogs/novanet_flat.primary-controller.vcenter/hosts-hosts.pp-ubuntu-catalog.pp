class { 'L23network::Hosts_file':
  hosts_file => '/etc/hosts',
  name       => 'L23network::Hosts_file',
  nodes      => [{'fqdn' => 'node-1.test.domain.local', 'internal_address' => '10.108.2.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-1', 'public_address' => '10.108.1.4', 'public_netmask' => '255.255.255.0', 'role' => 'primary-controller', 'storage_address' => '10.108.4.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '1', 'uid' => '1', 'user_node_name' => 'slave-01_controller'}, {'fqdn' => 'node-2.test.domain.local', 'internal_address' => '10.108.2.5', 'internal_netmask' => '255.255.255.0', 'name' => 'node-2', 'public_address' => '10.108.1.5', 'public_netmask' => '255.255.255.0', 'role' => 'controller', 'storage_address' => '10.108.4.3', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '2', 'uid' => '2', 'user_node_name' => 'slave-02_controller'}, {'fqdn' => 'node-3.test.domain.local', 'internal_address' => '10.108.2.6', 'internal_netmask' => '255.255.255.0', 'name' => 'node-3', 'public_address' => '10.108.1.6', 'public_netmask' => '255.255.255.0', 'role' => 'controller', 'storage_address' => '10.108.4.4', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '3', 'uid' => '3', 'user_node_name' => 'slave-03_controller'}, {'fqdn' => 'node-4.test.domain.local', 'internal_address' => '10.108.2.7', 'internal_netmask' => '255.255.255.0', 'name' => 'node-4', 'public_address' => '10.108.1.7', 'public_netmask' => '255.255.255.0', 'role' => 'compute', 'storage_address' => '10.108.4.5', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '4', 'uid' => '4', 'user_node_name' => 'slave-04_compute'}, {'fqdn' => 'node-5.test.domain.local', 'internal_address' => '10.108.2.8', 'internal_netmask' => '255.255.255.0', 'name' => 'node-5', 'public_address' => '10.108.1.8', 'public_netmask' => '255.255.255.0', 'role' => 'primary-mongo', 'storage_address' => '10.108.4.6', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '5', 'uid' => '5', 'user_node_name' => 'slave-05_mongo'}],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

host { 'node-1.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-1',
  ip           => '10.108.2.4',
  name         => 'node-1.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-2.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-2',
  ip           => '10.108.2.5',
  name         => 'node-2.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-3.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-3',
  ip           => '10.108.2.6',
  name         => 'node-3.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-4.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-4',
  ip           => '10.108.2.7',
  name         => 'node-4.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-5.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-5',
  ip           => '10.108.2.8',
  name         => 'node-5.test.domain.local',
  target       => '/etc/hosts',
}

stage { 'main':
  name => 'main',
}

