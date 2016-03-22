class osnailyfacter::openstack_network::agents::sriov {

  notice('MODULAR: openstack_network/agents/sriov.pp')

  $use_neutron     = hiera('use_neutron', false)
  $network_scheme  = hiera_hash('network_scheme', {})
  $neutron_config  = hiera_hash('neutron_config')
  $pci_vendor_devs = pick($neutron_config['supported_pci_vendor_devs'], false)

  if $use_neutron and $pci_vendor_devs {

    prepare_network_config($network_scheme)
    $pci_passthrough_whitelist = get_nic_passthrough_whitelist('sriov')
    $physical_device_mappings = nic_whitelist_to_mappings($pci_passthrough_whitelist)

    class { '::neutron::agents::ml2::sriov':
      physical_device_mappings => $physical_device_mappings,
      manage_service           => true,
      enabled                  => true,
    }

    # stub package for 'neutron::agents::sriov' class
    package { 'neutron':
      name   => 'binutils',
      ensure => 'installed',
    }

    # override neutron options
    $override_configuration = hiera_hash('configuration', {})
    override_resources { 'neutron_sriov_agent_config':
      data => $override_configuration['neutron_sriov_agent_config']
    }

  }

}
