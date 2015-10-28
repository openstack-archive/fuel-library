class { 'L23network::Hosts_file':
  hosts_file => '/etc/hosts',
  name       => 'L23network::Hosts_file',
  nodes      => [{'fqdn' => 'node-3.test.domain.local', 'internal_address' => '172.16.1.5', 'internal_netmask' => '255.255.255.0', 'name' => 'node-3', 'public_address' => '172.16.0.5', 'public_netmask' => '255.255.255.0', 'role' => 'primary-controller', 'storage_address' => '192.168.1.3', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '3', 'uid' => '3', 'user_node_name' => 'Untitled (19:f0)'}, {'fqdn' => 'node-4.test.domain.local', 'internal_address' => '172.16.1.7', 'internal_netmask' => '255.255.255.0', 'name' => 'node-4', 'public_address' => '172.16.0.7', 'public_netmask' => '255.255.255.0', 'role' => 'compute-vmware', 'storage_address' => '192.168.1.5', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '4', 'uid' => '4', 'user_node_name' => 'Untitled (c8:39)'}, {'fqdn' => 'node-5.test.domain.local', 'internal_address' => '172.16.1.6', 'internal_netmask' => '255.255.255.0', 'name' => 'node-5', 'public_address' => '172.16.0.6', 'public_netmask' => '255.255.255.0', 'role' => 'controller', 'storage_address' => '192.168.1.4', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '5', 'uid' => '5', 'user_node_name' => 'Untitled (56:9f)'}, {'fqdn' => 'node-6.test.domain.local', 'internal_address' => '172.16.1.3', 'internal_netmask' => '255.255.255.0', 'name' => 'node-6', 'public_address' => '172.16.0.8', 'public_netmask' => '255.255.255.0', 'role' => 'controller', 'storage_address' => '192.168.1.1', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '6', 'uid' => '6', 'user_node_name' => 'Untitled (8b:3c)'}, {'fqdn' => 'node-7.test.domain.local', 'internal_address' => '172.16.1.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-7', 'public_address' => '172.16.0.4', 'public_netmask' => '255.255.255.0', 'role' => 'cinder-vmware', 'storage_address' => '192.168.1.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '7', 'uid' => '7', 'user_node_name' => 'Untitled (c1:0b)'}],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

host { 'node-3.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-3',
  ip           => '172.16.1.5',
  name         => 'node-3.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-4.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-4',
  ip           => '172.16.1.7',
  name         => 'node-4.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-5.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-5',
  ip           => '172.16.1.6',
  name         => 'node-5.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-6.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-6',
  ip           => '172.16.1.3',
  name         => 'node-6.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-7.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-7',
  ip           => '172.16.1.4',
  name         => 'node-7.test.domain.local',
  target       => '/etc/hosts',
}

stage { 'main':
  name => 'main',
}

