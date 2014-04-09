class plugin_neutronnsx::install_ovs
{
  include $::plugin_neutronnsx::params

  if has_key($::fuel_settings,'nsx_plugin') and $::fuel_settings['nsx_plugin']['metadata']['enabled'] {
     case $::osfamily {
       /(?i)debian/: {
         package { 'dkms':
           ensure => present,
         } ->
         package { 'openvswitch-common':
           provider => 'rdpkg',
           source  => $::fuel_settings['nsx_plugin']['packages_url'],
         } ->
         package { 'openvswitch-datapath-dkms':
           provider => 'rdpkg',
           source  => $::fuel_settings['nsx_plugin']['packages_url'],
           notify  => Service['openvswitch-service'],
         } ->
         package { 'openvswitch-switch':
           provider => 'rdpkg',
           source  => $::fuel_settings['nsx_plugin']['packages_url'],
           notify  => Service['openvswitch-service'],
         } ->
         package { 'nicira-ovs-hypervisor-node':
           provider => 'rdpkg',
           source  => $::fuel_settings['nsx_plugin']['packages_url'],
         } -> Service['nicira-ovs-hypervisor-node']
       }
       /(?i)redhat/: {
         $nsx_url = $::fuel_settings['nsx_plugin']['packages_url']
         $kmod_openvswitch_pkg_url           = "${nsx_url}/${::plugin_neutronnsx::params::kmod_openvswitch_package}"
         $openvswitch_pkg_url                = "${nsx_url}/${::plugin_neutronnsx::params::openvswitch_package}"
         $nicira_ovs_hypervisor_node_pkg_url = "${nsx_url}/${::plugin_neutronnsx::params::nicira_ovs_hypervisor_node_package}"

         package { 'kmod-openvswitch':
           provider => 'rpm',
           source => $kmod_openvswitch_pkg_url,
         } ->
         package { 'openvswitch':
           provider => 'rpm',
           source => $openvswitch_pkg_url,
           notify => Service['openvswitch-service'],
         } ->
         package { 'nicira-ovs-hypervisor-node':
           provider => 'rpm',
           source => $nicira_ovs_hypervisor_node_pkg_url,
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
}
