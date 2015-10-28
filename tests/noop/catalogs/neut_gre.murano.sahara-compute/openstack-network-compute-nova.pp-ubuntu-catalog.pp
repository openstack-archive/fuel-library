augeas { 'sysctl-net.bridge.bridge-nf-call-arptables':
  before  => 'Service[libvirt]',
  changes => 'set net.bridge.bridge-nf-call-arptables '1'',
  context => '/files/etc/sysctl.conf',
  name    => 'sysctl-net.bridge.bridge-nf-call-arptables',
}

augeas { 'sysctl-net.bridge.bridge-nf-call-ip6tables':
  before  => 'Service[libvirt]',
  changes => 'set net.bridge.bridge-nf-call-ip6tables '1'',
  context => '/files/etc/sysctl.conf',
  name    => 'sysctl-net.bridge.bridge-nf-call-ip6tables',
}

augeas { 'sysctl-net.bridge.bridge-nf-call-iptables':
  before  => 'Service[libvirt]',
  changes => 'set net.bridge.bridge-nf-call-iptables '1'',
  context => '/files/etc/sysctl.conf',
  name    => 'sysctl-net.bridge.bridge-nf-call-iptables',
}

class { 'Nova::Compute::Neutron':
  force_snat_range   => '0.0.0.0/0',
  libvirt_vif_driver => 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver',
  name               => 'Nova::Compute::Neutron',
}

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

exec { 'destroy_libvirt_default_network':
  command => 'virsh net-destroy default',
  onlyif  => 'virsh net-info default | grep -qE "Active:.* yes"',
  path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  require => 'Service[libvirt]',
  tries   => '3',
}

exec { 'remove_nova-network_override':
  command => 'rm -f /etc/init/nova-network.override',
  onlyif  => 'test -f /etc/init/nova-network.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'undefine_libvirt_default_network':
  command => 'virsh net-undefine default',
  onlyif  => 'virsh net-info default 2>&1 > /dev/null',
  path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  require => 'Exec[destroy_libvirt_default_network]',
  tries   => '3',
}

exec { 'wait-for-int-br':
  before    => 'Service[nova-compute]',
  command   => 'ovs-vsctl br-exists br-int',
  path      => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
  tries     => '10',
  try_sleep => '6',
}

file { 'create_nova-network_override':
  ensure  => 'present',
  before  => 'Exec[remove_nova-network_override]',
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/nova-network.override',
}

file_line { 'clear_emulator_capabilities':
  line   => 'clear_emulator_capabilities = 0',
  name   => 'clear_emulator_capabilities',
  notify => 'Service[libvirt]',
  path   => '/etc/libvirt/qemu.conf',
}

file_line { 'no_qemu_selinux':
  line   => 'security_driver = "none"',
  name   => 'no_qemu_selinux',
  notify => 'Service[libvirt]',
  path   => '/etc/libvirt/qemu.conf',
}

nova_config { 'DEFAULT/dhcp_domain':
  name   => 'DEFAULT/dhcp_domain',
  notify => 'Service[nova-compute]',
  value  => 'novalocal',
}

nova_config { 'DEFAULT/firewall_driver':
  name   => 'DEFAULT/firewall_driver',
  notify => 'Service[nova-compute]',
  value  => 'nova.virt.firewall.NoopFirewallDriver',
}

nova_config { 'DEFAULT/force_snat_range':
  name   => 'DEFAULT/force_snat_range',
  notify => 'Service[nova-compute]',
  value  => '0.0.0.0/0',
}

nova_config { 'DEFAULT/linuxnet_interface_driver':
  name   => 'DEFAULT/linuxnet_interface_driver',
  notify => 'Service[nova-compute]',
  value  => 'nova.network.linux_net.LinuxOVSInterfaceDriver',
}

nova_config { 'DEFAULT/linuxnet_ovs_integration_bridge':
  name   => 'DEFAULT/linuxnet_ovs_integration_bridge',
  notify => 'Service[nova-compute]',
  value  => 'br-int',
}

nova_config { 'DEFAULT/network_api_class':
  name   => 'DEFAULT/network_api_class',
  notify => 'Service[nova-compute]',
  value  => 'nova.network.neutronv2.api.API',
}

nova_config { 'DEFAULT/network_device_mtu':
  name   => 'DEFAULT/network_device_mtu',
  notify => 'Service[nova-compute]',
  value  => '65000',
}

nova_config { 'DEFAULT/security_group_api':
  name   => 'DEFAULT/security_group_api',
  notify => 'Service[nova-compute]',
  value  => 'neutron',
}

nova_config { 'DEFAULT/vif_plugging_is_fatal':
  name   => 'DEFAULT/vif_plugging_is_fatal',
  notify => 'Service[nova-compute]',
  value  => 'true',
}

nova_config { 'DEFAULT/vif_plugging_timeout':
  name   => 'DEFAULT/vif_plugging_timeout',
  notify => 'Service[nova-compute]',
  value  => '300',
}

nova_config { 'libvirt/vif_driver':
  name   => 'libvirt/vif_driver',
  notify => 'Service[nova-compute]',
  value  => 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver',
}

nova_config { 'neutron/admin_auth_url':
  name   => 'neutron/admin_auth_url',
  notify => 'Service[nova-compute]',
  value  => 'http://192.168.0.2:35357/v2.0',
}

nova_config { 'neutron/admin_password':
  name   => 'neutron/admin_password',
  notify => 'Service[nova-compute]',
  secret => 'true',
  value  => 'oT56DSZF',
}

nova_config { 'neutron/admin_tenant_name':
  name   => 'neutron/admin_tenant_name',
  notify => 'Service[nova-compute]',
  value  => 'services',
}

nova_config { 'neutron/admin_username':
  name   => 'neutron/admin_username',
  notify => 'Service[nova-compute]',
  value  => 'neutron',
}

nova_config { 'neutron/auth_strategy':
  name   => 'neutron/auth_strategy',
  notify => 'Service[nova-compute]',
  value  => 'keystone',
}

nova_config { 'neutron/ca_certificates_file':
  ensure => 'absent',
  name   => 'neutron/ca_certificates_file',
  notify => 'Service[nova-compute]',
}

nova_config { 'neutron/default_tenant_id':
  name   => 'neutron/default_tenant_id',
  notify => 'Service[nova-compute]',
  value  => 'default',
}

nova_config { 'neutron/extension_sync_interval':
  name   => 'neutron/extension_sync_interval',
  notify => 'Service[nova-compute]',
  value  => '600',
}

nova_config { 'neutron/ovs_bridge':
  name   => 'neutron/ovs_bridge',
  notify => 'Service[nova-compute]',
  value  => 'br-int',
}

nova_config { 'neutron/region_name':
  name   => 'neutron/region_name',
  notify => 'Service[nova-compute]',
  value  => 'RegionOne',
}

nova_config { 'neutron/url':
  name   => 'neutron/url',
  notify => 'Service[nova-compute]',
  value  => 'http://192.168.0.2:9696',
}

nova_config { 'neutron/url_timeout':
  name   => 'neutron/url_timeout',
  notify => 'Service[nova-compute]',
  value  => '30',
}

service { 'libvirt':
  ensure   => 'running',
  enable   => 'true',
  name     => 'libvirtd',
  notify   => 'Exec[destroy_libvirt_default_network]',
  provider => 'upstart',
}

service { 'nova-compute':
  ensure => 'running',
  name   => 'nova-compute',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'nova-network':
  name         => 'nova-network',
  package_name => 'nova-network',
  service_name => 'nova-network',
}

