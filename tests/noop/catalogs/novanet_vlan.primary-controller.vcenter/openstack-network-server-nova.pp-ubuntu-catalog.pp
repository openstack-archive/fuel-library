class { 'Nova::Network::Vlan':
  dhcp_domain         => 'novalocal',
  dhcpbridge          => '/usr/bin/nova-dhcpbridge',
  dhcpbridge_flagfile => '/etc/nova/nova.conf',
  fixed_range         => '10.0.0.0/16',
  force_dhcp_release  => 'true',
  name                => 'Nova::Network::Vlan',
  public_interface    => '',
  vlan_interface      => 'eth1',
  vlan_start          => '103',
}

class { 'Nova::Network':
  config_overrides  => {'vlan_start' => '103'},
  create_networks   => 'true',
  dns1              => '8.8.4.4',
  dns2              => '8.8.8.8',
  enabled           => 'false',
  ensure_package    => 'installed',
  fixed_range       => '10.0.0.0/16',
  floating_range    => 'false',
  install_service   => 'false',
  name              => 'Nova::Network',
  network_manager   => 'nova.network.manager.VlanManager',
  network_size      => '256',
  num_networks      => '1',
  private_interface => 'eth1',
  public_interface  => '',
}

class { 'Nova::Params':
  name => 'Nova::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Sysctl::Base':
  name => 'Sysctl::Base',
}

class { 'main':
  name => 'main',
}

file { '/etc/nova/nova.conf':
  ensure => 'present',
  before => 'Nova_network[nova-vm-net]',
  path   => '/etc/nova/nova.conf',
}

file { '/etc/sysctl.conf':
  ensure => 'present',
  group  => '0',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/sysctl.conf',
}

nova::manage::network { 'nova-vm-net':
  dns1         => '8.8.4.4',
  dns2         => '8.8.8.8',
  label        => 'novanetwork',
  name         => 'nova-vm-net',
  network      => '10.0.0.0/16',
  network_size => '256',
  num_networks => '1',
  vlan_start   => '103',
}

nova_config { 'DEFAULT/dhcp_domain':
  name  => 'DEFAULT/dhcp_domain',
  value => 'novalocal',
}

nova_config { 'DEFAULT/dhcpbridge':
  name  => 'DEFAULT/dhcpbridge',
  value => '/usr/bin/nova-dhcpbridge',
}

nova_config { 'DEFAULT/dhcpbridge_flagfile':
  name  => 'DEFAULT/dhcpbridge_flagfile',
  value => '/etc/nova/nova.conf',
}

nova_config { 'DEFAULT/fixed_range':
  name  => 'DEFAULT/fixed_range',
  value => '10.0.0.0/16',
}

nova_config { 'DEFAULT/force_dhcp_release':
  name  => 'DEFAULT/force_dhcp_release',
  value => 'true',
}

nova_config { 'DEFAULT/force_snat_range':
  name  => 'DEFAULT/force_snat_range',
  value => '0.0.0.0/0',
}

nova_config { 'DEFAULT/network_manager':
  name  => 'DEFAULT/network_manager',
  value => 'nova.network.manager.VlanManager',
}

nova_config { 'DEFAULT/vlan_interface':
  name  => 'DEFAULT/vlan_interface',
  value => 'eth1',
}

nova_config { 'DEFAULT/vlan_start':
  name  => 'DEFAULT/vlan_start',
  value => '103',
}

nova_network { 'nova-vm-net':
  ensure       => 'present',
  dns1         => '8.8.4.4',
  dns2         => '8.8.8.8',
  label        => 'novanetwork',
  network      => '10.0.0.0/16',
  network_size => '256',
  num_networks => '1',
  vlan_start   => '103',
}

stage { 'main':
  name => 'main',
}

sysctl::value { 'net.ipv4.ip_forward':
  key     => 'net.ipv4.ip_forward',
  name    => 'net.ipv4.ip_forward',
  require => 'Class[Sysctl::Base]',
  value   => '1',
}

sysctl { 'net.ipv4.ip_forward':
  before => 'Sysctl_runtime[net.ipv4.ip_forward]',
  name   => 'net.ipv4.ip_forward',
  val    => '1',
}

sysctl_runtime { 'net.ipv4.ip_forward':
  name => 'net.ipv4.ip_forward',
  val  => '1',
}

