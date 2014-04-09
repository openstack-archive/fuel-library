class plugin_neutronnsx::install_ovs
{
  if has_key($::fuel_settings,'nsx_plugin') and $::fuel_settings['nsx_plugin']['nicira'] {
    if $::osfamily =~ /(?i)debian/ {
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
	notify  => Service['openvswitch-service']
      } ->
      package { 'nicira-ovs-hypervisor-node':
	provider => 'rdpkg',
	source  => $::fuel_settings['nsx_plugin']['packages_url'],
      } ->
      service {'nicira-ovs-hypervisor-node': 
        ensure => running, 
      }
    }
    service { 'openvswitch-service':
      ensure    => running,
      name      => $::l23network::params::ovs_service_name,
      enable    => true,
      hasstatus => true,
      status    => '/etc/init.d/openvswitch status |grep "vswitchd is running"',
      require   => Package['nicira-ovs-hypervisor-node'],
    }
  }
}
