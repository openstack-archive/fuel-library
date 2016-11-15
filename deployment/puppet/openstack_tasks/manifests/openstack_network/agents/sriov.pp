class openstack_tasks::openstack_network::agents::sriov {

  notice('MODULAR: openstack_network/agents/sriov.pp')

  $network_scheme          = hiera_hash('network_scheme', {})
  $neutron_config          = hiera_hash('neutron_config')
  $neutron_advanced_config = hiera_hash('neutron_advanced_configuration', {})
  $enable_qos              = pick($neutron_advanced_config['neutron_qos'], false)

  prepare_network_config($network_scheme)
  $pci_passthrough_whitelist = get_nic_passthrough_whitelist('sriov')

  if $pci_passthrough_whitelist {
    $physical_device_mappings = nic_whitelist_to_mappings($pci_passthrough_whitelist)

    class { '::neutron::agents::ml2::sriov':
      physical_device_mappings => $physical_device_mappings,
      extensions               => $enable_qos ? { true => ['qos'], default => ''},
      manage_service           => true,
      enabled                  => true,
    }

    # stub package for 'neutron::agents::sriov' class
    package { 'neutron':
      name   => 'binutils',
      ensure => 'installed',
    }
  }

}
