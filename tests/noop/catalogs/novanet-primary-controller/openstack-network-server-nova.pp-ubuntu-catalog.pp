class { 'Nova::Network::Flatdhcp':
  dhcp_domain         => 'novalocal',
  dhcpbridge          => '/usr/bin/nova-dhcpbridge',
  dhcpbridge_flagfile => '/etc/nova/nova.conf',
  fixed_range         => '10.0.0.0/16',
  flat_injected       => 'false',
  flat_interface      => 'eth0.103',
  flat_network_bridge => 'br100',
  force_dhcp_release  => 'true',
  name                => 'Nova::Network::Flatdhcp',
  public_interface    => '',
}

class { 'Nova::Network':
  config_overrides  => {},
  create_networks   => 'true',
  dns1              => '8.8.4.4',
  dns2              => '8.8.8.8',
  enabled           => 'false',
  ensure_package    => 'installed',
  fixed_range       => '10.0.0.0/16',
  floating_range    => 'false',
  install_service   => 'false',
  name              => 'Nova::Network',
  network_manager   => 'nova.network.manager.FlatDHCPManager',
  network_size      => '65536',
  num_networks      => '1',
  private_interface => 'eth0.103',
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
  network_size => '65536',
  num_networks => '1',
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

nova_config { 'DEFAULT/flat_injected':
  name  => 'DEFAULT/flat_injected',
  value => 'false',
}

nova_config { 'DEFAULT/flat_interface':
  name  => 'DEFAULT/flat_interface',
  value => 'eth0.103',
}

nova_config { 'DEFAULT/flat_network_bridge':
  name  => 'DEFAULT/flat_network_bridge',
  value => 'br100',
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
  value => 'nova.network.manager.FlatDHCPManager',
}

nova_network { 'nova-vm-net':
  ensure       => 'present',
  dns1         => '8.8.4.4',
  dns2         => '8.8.8.8',
  label        => 'novanetwork',
  network      => '10.0.0.0/16',
  network_size => '65536',
  num_networks => '1',
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

