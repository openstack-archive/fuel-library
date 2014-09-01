class plugin_neutronnsx::install_ovs (
  $packages_url,
) {
  include $::neutron::params
  case $::osfamily {
    /(?i)debian/: {
      Package<| title=="openvswitch-common" |> {
        name       => "openvswitch-common",
        source  => $packages_url,
        provider   => 'rdpkg',
      }
      Package<| title=="openvswitch-datapath" |> {
        name       => "openvswitch-datapath-dkms",
        source  => $packages_url,
        provider   => 'rdpkg',
      }

      package { 'dkms':
        ensure => present,
      }

      package { 'openvswitch-nsx-switch':
        name => 'CHANGEME',
        provider => 'rdpkg',
        source  => $packages_url,
      }
      Package<| title == 'openvswitch-nsx-switch' |> {
        name => 'openvswitch-switch',
      }

      package { 'nicira-ovs-hypervisor-node':
        provider => 'rdpkg',
        source  => $packages_url,
      }

      Package['dkms'] -> Package['openvswitch-datapath']

      Package['openvswitch-common'] -> Package['openvswitch-nsx-switch'] ->
      Package['nicira-ovs-hypervisor-node'] ~> Service['nicira-ovs-hypervisor-node']
    }
    /(?i)redhat/: {
      Package<| title=="openvswitch-common" |> {
        name       => "openvswitch",
        source  => $packages_url,
        provider   => 'rrpm',
      }
      Package<| title=="openvswitch-datapath" |> {
        name       => "kmod-openvswitch",
        source  => $packages_url,
        provider   => 'rrpm',
      }

      package { 'nicira-ovs-hypervisor-node':
        provider => 'rrpm',
        source => $packages_url,
      }

      Package['openvswitch-common'] ->
      Package['nicira-ovs-hypervisor-node'] ~>
      Service['nicira-ovs-hypervisor-node']
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }

  service { 'nicira-ovs-hypervisor-node':
    ensure => running,
    enable => true,
    hasstatus  => true,
    hasrestart => true,
  }

  Service['nicira-ovs-hypervisor-node'] -> Service['openvswitch-service']
}
