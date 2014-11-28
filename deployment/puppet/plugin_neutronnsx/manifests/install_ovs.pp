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
      package { 'openvswitch-nsx-datapath':
        name => "openvswitch-datapath-dkms",
        source => $packages_url,
        provider => 'rdpkg',
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

      # Delete this file, because it uses bash-syntax for functions defenitions
      # but specified interpreter is /bin/sh and in Ubuntu /bin/sh->/bin/dash
      file{ 'nsx-alias.sh_profile_hack':
        path => '/etc/profile.d/nsx-alias.sh',
        ensure => absent,
      }

      Package['dkms'] -> Package['openvswitch-nsx-datapath']

      Package['openvswitch-common'] -> Package['openvswitch-nsx-switch'] ->
      Package['nicira-ovs-hypervisor-node'] -> File['nsx-alias.sh_profile_hack'] ~>
      Service['nicira-ovs-hypervisor-node']
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

      package { 'openstack-neutron-openvswitch':
        name => 'openstack-neutron-openvswitch',
        ensure => present,
      }

      Package['openvswitch-common'] ->
      Package['openstack-neutron-openvswitch'] ->
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
