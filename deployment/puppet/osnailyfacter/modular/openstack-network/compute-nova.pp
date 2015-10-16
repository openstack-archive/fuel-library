notice('MODULAR: openstack-network/compute-nova.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {
  include nova::params
  $nova_hash = hiera_hash('nova')
  $libvirt_vif_driver = pick($nova_hash['libvirt_vif_driver'], 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver')
  $neutron_integration_bridge = 'br-int'

  service { 'libvirt' :
    ensure   => 'running',
    enable   => true,
  # Workaround for bug LP #1469308
  # also service name for Ubuntu and Centos is the same.
    name     => 'libvirtd',
    provider => $nova::params::special_service_provider,
  }

  exec { 'destroy_libvirt_default_network':
    command => 'virsh net-destroy default',
    onlyif  => 'virsh net-info default | grep -qE "Active:.* yes"',
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    tries   => 3,
    require => Service['libvirt'],
  }

  exec { 'undefine_libvirt_default_network':
    command => 'virsh net-undefine default',
    onlyif  => 'virsh net-info default 2>&1 > /dev/null',
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    tries   => 3,
    require => Exec['destroy_libvirt_default_network'],
  }

  Service['libvirt'] ~> Exec['destroy_libvirt_default_network']

# script called by qemu needs to manipulate the tap device
  file_line { 'clear_emulator_capabilities':
    path    => '/etc/libvirt/qemu.conf',
    line    => 'clear_emulator_capabilities = 0',
    notify  => Service['libvirt']
  }

  file_line { 'no_qemu_selinux':
    path    => '/etc/libvirt/qemu.conf',
    line    => 'security_driver = "none"',
    notify  => Service['libvirt']
  }

  class { 'nova::compute::neutron':
    libvirt_vif_driver => $libvirt_vif_driver,
  }

  nova_config {
    'DEFAULT/linuxnet_interface_driver': value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
    'DEFAULT/linuxnet_ovs_integration_bridge': value => $neutron_integration_bridge;
    'DEFAULT/network_device_mtu': value => '65000';
  }

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

# We need to restart nova-compute service in orderto apply new settings
  service { 'nova-compute':
    ensure => 'running',
    name   => $::nova::params::compute_service_name,
  }
  Nova_config<| |> ~> Service['nova-compute']

  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'nova-network':
      package_name => 'nova-network',
    }
  }

} else {

  $network_scheme          = hiera('network_scheme', { })
  prepare_network_config($network_scheme)

  $nova_hash               = hiera_hash('nova_hash', { })
  $bind_address            = get_network_role_property('nova/api', 'ipaddr')
  $public_int              = get_network_role_property('public/vip', 'interface')
  $private_interface       = get_network_role_property('nova/private', 'interface')
  $public_interface        = $public_int ? { undef=>'', default => $public_int }
  $auto_assign_floating_ip = hiera('auto_assign_floating_ip', false)
  $nova_rate_limits        = hiera('nova_rate_limits')
  $network_size            = hiera('network_size', undef)
  $network_manager         = hiera('network_manager', undef)
  $network_config          = hiera('network_config', { })
  $create_networks         = true
  $num_networks            = hiera('num_networks', '1')
  $novanetwork_params      = hiera('novanetwork_parameters')
  $fixed_range             = hiera('fixed_network_range')
  $use_vcenter             = hiera('use_vcenter', false)
  $enabled_apis            = 'metadata'
  $dns_nameservers         = hiera_array('dns_nameservers', [])

  if ! $fixed_range {
    fail('Must specify the fixed range when using nova-networks')
  }

  if $use_vcenter {
    $enable_nova_net = false
    nova_config {
      'DEFAULT/multi_host': value => 'False';
      'DEFAULT/send_arp_for_ha': value => 'False';
    }
  } else {
    include keystone::python

    Nova_config<| |> -> Service['nova-network']

    case $::osfamily {
      'RedHat': {
        $pymemcache_package_name      = 'python-memcached'
      }
      'Debian': {
        $pymemcache_package_name      = 'python-memcache'
      }
      default: {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem},\
              module ${module_name} only support osfamily RedHat and Debian")
      }
    }

    if !defined(Package[$pymemcache_package_name]) {
      package { $pymemcache_package_name:
        ensure => 'present',
      } ->
      Nova::Generic_service <| title == 'api' |>
    }

    class { 'nova::api':
      ensure_package        => 'installed',
      enabled               => true,
      admin_tenant_name     => 'services',
      admin_user            => 'nova',
      admin_password        => $nova_hash['user_password'],
      enabled_apis          => $enabled_apis,
      api_bind_address      => $bind_address,
      ratelimits            => $nova_rate_limits,
    # NOTE(bogdando) 1 api worker for compute node is enough
      osapi_compute_workers => '1',
    }

    if $::operatingsystem == 'Ubuntu' {
      tweaks::ubuntu_service_override { 'nova-api':
        package_name => 'nova-api',
      }
    }

    nova_config {
      'DEFAULT/multi_host'      : value => 'True';
      'DEFAULT/send_arp_for_ha' : value => 'True';
      'DEFAULT/metadata_host'   : value => $bind_address;
    }

    if ! $public_interface {
      fail('public_interface must be defined for multi host compute nodes')
    }

    $enable_nova_net = true

    if $auto_assign_floating_ip {
      nova_config { 'DEFAULT/auto_assign_floating_ip': value => 'True' }
    }
  }

# Stub for networking-refresh that is needed by Nova::Network/Nova::Generic_service[network]
# We do not need it due to l23network is doing all stuff
# BTW '/sbin/ifdown -a ; /sbin/ifup -a' does not work on CentOS
  exec { 'networking-refresh':
    command     => '/bin/echo "networking-refresh has been refreshed"',
    refreshonly => true,
  }

# Stubs for nova_paste_api_ini
  exec { 'post-nova_config':
    command     => '/bin/echo "Nova config has changed"',
    refreshonly => true,
  }

# Stubs for nova_network
  file { '/etc/nova/nova.conf':
    ensure => 'present',
  }

# Stubs for nova-api
  package { 'nova-common':
    name   => 'binutils',
    ensure => 'installed',
  }

  if $::operatingsystem == 'Ubuntu' {
    tweaks::ubuntu_service_override { 'nova-network':
      package_name => 'nova-network',
    }
  }

  class { 'nova::network':
    ensure_package    => 'installed',
    private_interface => $private_interface,
    public_interface  => $public_interface,
    fixed_range       => $fixed_range,
    floating_range    => false,
    network_manager   => $network_manager,
    config_overrides  => $network_config,
    create_networks   => $create_networks,
    num_networks      => $num_networks,
    network_size      => $network_size,
    dns1              => $dns_nameservers[0],
    dns2              => $dns_nameservers[1],
    enabled           => $enable_nova_net,
    install_service   => $enable_nova_net,
  }
#NOTE(aglarendil): lp/1381164
  nova_config { 'DEFAULT/force_snat_range': value => '0.0.0.0/0' }

}
