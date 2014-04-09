class plugin_neutronnsx::install_ovs
{
  $packages_url = $::fuel_settings['nsx_plugin']['packages_url']
  include $::neutron::params
  case $::osfamily {
    /(?i)debian/: {
      package { 'dkms':
        ensure => present,
      } ->
      package { 'openvswitch-common':
        provider => 'rdpkg',
        source  => $packages_url,
      } ->
      package { 'openvswitch-datapath-dkms':
        provider => 'rdpkg',
        source  => $packages_url,
        notify  => Service['openvswitch-service'],
      } ->
      package { 'openvswitch-switch':
        provider => 'rdpkg',
        source  => $packages_url,
        notify  => Service['openvswitch-service'],
      } ->
      package { 'nicira-ovs-hypervisor-node':
        provider => 'rdpkg',
        source  => $packages_url,
      } -> Service['nicira-ovs-hypervisor-node']
    }
    /(?i)redhat/: {
      package { 'kmod-openvswitch':
        provider => 'rrpm',
        source => $packages_url,
      } ->
      package { 'openvswitch':
        provider => 'rrpm',
        source => $packages_url,
        notify => Service['openvswitch-service'],
      } ->
      package { 'nicira-ovs-hypervisor-node':
        provider => 'rrpm',
        source => $packages_url,
      } -> Service['nicira-ovs-hypervisor-node']
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }

  service { 'nicira-ovs-hypervisor-node':
    ensure => running,
    enable => true,
    hasstatus => true,
  }

  service { 'openvswitch-service':
    ensure    => running,
    name      => $::l23network::params::ovs_service_name,
    enable    => true,
    hasstatus => true,
    status    => $::l23network::params::ovs_status_cmd,
    require   => Package['nicira-ovs-hypervisor-node'],
  }
}
