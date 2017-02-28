class openstack_tasks::openstack_network::compute_nova {

  notice('MODULAR: openstack_network/compute_nova.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  prepare_network_config($network_scheme)

  include ::nova::params
  $neutron_config             = hiera_hash('neutron_config', {})
  $neutron_integration_bridge = 'br-int'
  $nova_hash                  = hiera_hash('nova', {})
  $libvirt_vif_driver         = pick($nova_hash['libvirt_vif_driver'], 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver')

  $management_vip             = hiera('management_vip')
  $service_endpoint           = hiera('service_endpoint', $management_vip)
  $admin_password             = dig44($neutron_config, ['keystone', 'admin_password'])
  $admin_tenant_name          = dig44($neutron_config, ['keystone', 'admin_tenant'], 'services')
  $admin_username             = dig44($neutron_config, ['keystone', 'admin_user'], 'neutron')
  $region_name                = hiera('region', 'RegionOne')
  $auth_api_version           = 'v3'
  $ssl_hash                   = hiera_hash('use_ssl', {})

  $admin_identity_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

  $neutron_internal_protocol  = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'protocol', 'http')
  $neutron_internal_endpoint  = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'hostname', [hiera('neutron_endpoint', ''), $management_vip])

  $neutron_auth_url           = "${admin_identity_protocol}://${admin_identity_address}:35357/${auth_api_version}"
  $neutron_url                = "${neutron_internal_protocol}://${neutron_internal_endpoint}:9696"

  $nova_migration_ip          =  get_network_role_property('nova/migration', 'ipaddr')

  service { 'libvirt' :
    ensure   => 'running',
    enable   => true,
    name     => 'libvirt-bin',
    provider => $::nova::params::special_service_provider,
  }

  exec { 'destroy_libvirt_default_network':
    command => 'virsh net-destroy default',
    onlyif  => "virsh net-list | grep -qE '^\s*default\s'",
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    tries   => 3,
    require => Service['libvirt'],
  }

  exec { 'undefine_libvirt_default_network':
    command => 'virsh net-undefine default',
    onlyif  => "virsh net-list --all | grep -qE '^\s*default\s'",
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    tries   => 3,
    require => Exec['destroy_libvirt_default_network'],
  }

  Service['libvirt'] ~> Exec['destroy_libvirt_default_network']
  Service['libvirt'] ~> Exec['undefine_libvirt_default_network']

  # script called by qemu needs to manipulate the tap device
  file_line { 'clear_emulator_capabilities':
    path   => '/etc/libvirt/qemu.conf',
    line   => 'clear_emulator_capabilities = 0',
    notify => Service['libvirt']
  }

  class { '::nova::compute::neutron':
    libvirt_vif_driver => $libvirt_vif_driver,
  }

  nova_config {
    'DEFAULT/linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
    'DEFAULT/linuxnet_ovs_integration_bridge': value => $neutron_integration_bridge;
    'DEFAULT/my_ip':                           value => $nova_migration_ip;
  }

  class { '::nova::network::neutron' :
    neutron_password     => $admin_password,
    neutron_project_name => $admin_tenant_name,
    neutron_region_name  => $region_name,
    neutron_username     => $admin_username,
    neutron_auth_url     => $neutron_auth_url,
    neutron_url          => $neutron_url,
    neutron_ovs_bridge   => $neutron_integration_bridge,
  }

  # Remove this once nova package is updated and contains
  # use_neutron set to true by default LP #1668623
  ensure_resource('nova_config', 'DEFAULT/use_neutron', {'value' => true })

  augeas { 'sysctl-net.bridge.bridge-nf-call-arptables':
    context => '/files/etc/sysctl.conf',
    changes => "set net.bridge.bridge-nf-call-arptables '1'",
    before  => Service['libvirt'],
  }
  augeas { 'sysctl-net.bridge.bridge-nf-call-iptables':
    context => '/files/etc/sysctl.conf',
    changes => "set net.bridge.bridge-nf-call-iptables '1'",
    before  => Service['libvirt'],
  }
  augeas { 'sysctl-net.bridge.bridge-nf-call-ip6tables':
    context => '/files/etc/sysctl.conf',
    changes => "set net.bridge.bridge-nf-call-ip6tables '1'",
    before  => Service['libvirt'],
  }
}
