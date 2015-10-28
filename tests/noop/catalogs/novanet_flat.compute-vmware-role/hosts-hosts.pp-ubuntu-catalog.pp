class { 'L23network::Hosts_file':
  hosts_file => '/etc/hosts',
  name       => 'L23network::Hosts_file',
  nodes      => [{'fqdn' => 'node-1.test.domain.local', 'internal_address' => '10.109.7.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-1', 'public_address' => '10.109.6.4', 'public_netmask' => '255.255.255.0', 'role' => 'primary-controller', 'storage_address' => '10.109.9.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '1', 'uid' => '1', 'user_node_name' => 'slave-01_controller'}, {'fqdn' => 'node-2.test.domain.local', 'internal_address' => '10.109.7.5', 'internal_netmask' => '255.255.255.0', 'name' => 'node-2', 'public_address' => '10.109.6.5', 'public_netmask' => '255.255.255.0', 'role' => 'compute-vmware', 'storage_address' => '10.109.9.3', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '2', 'uid' => '2', 'user_node_name' => 'slave-02_compute-vmware'}],
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
  ip           => '10.109.7.4',
  name         => 'node-1.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-2.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-2',
  ip           => '10.109.7.5',
  name         => 'node-2.test.domain.local',
  target       => '/etc/hosts',
}

stage { 'main':
  name => 'main',
}

