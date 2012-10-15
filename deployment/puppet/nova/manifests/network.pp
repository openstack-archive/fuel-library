#
# [private_interface] Interface used by private network.
# [public_interface] Interface used to connect vms to public network.
# [fixed_range] Fixed private network range.
# [num_networks] Number of networks that fixed range network should be
#  split into.
# [floating_range] Range of floating ip addresses to create.
# [enabled] Rather the network service should be enabled.
# [network_manager] The type of network manager to use.
# [network_config]
# [create_networks] Rather actual nova networks should be created using
#   the fixed and floating ranges provided.
#
class nova::network(
  $private_interface,
  $fixed_range,
  $public_interface = undef,
  $num_networks     = 1,
  $network_size     = 255,
  $floating_range   = false,
  $enabled          = false,
  $network_manager  = 'nova.network.manager.FlatDHCPManager',
  $config_overrides = {},
  $create_networks  = true,
  $ensure_package   = 'present',
  $install_service  = true
) {

  include nova::params

  # forward all ipv4 traffic
  # this is required for the vms to pass through the gateways
  # public interface
  Exec {
    path => $::path
  }

  sysctl::value { 'net.ipv4.ip_forward':
    value => '1'
  }

  if $floating_range {
    nova_config { 'floating_range':   value => $floating_range }
  }

  if $install_service {
    nova::generic_service { 'network':
      enabled        => $enabled,
      package_name   => $::nova::params::network_package_name,
      service_name   => $::nova::params::network_service_name,
      ensure_package => $ensure_package,
      before         => Exec['networking-refresh']
    }
  }

  if $create_networks {
    nova::manage::network { 'nova-vm-net':
      network       => $fixed_range,
      num_networks  => $num_networks,
      network_size  => $network_size,
    }
    if $floating_range {
      nova::manage::floating { 'nova-vm-floating':
        network       => $floating_range,
      }
    }
  }

  case $network_manager {

    'nova.network.manager.FlatDHCPManager': {
      # I am not proud of this
      $parameters = { fixed_range      => $fixed_range,
                      public_interface => $public_interface,
                      flat_interface   => $private_interface
      }
      $resource_parameters = merge($config_overrides, $parameters)
      $flatdhcp_resource = {'nova::network::flatdhcp' => $resource_parameters }
      create_resources('class', $flatdhcp_resource)
    }
    'nova.network.manager.FlatManager': {
      $parameters = { fixed_range      => $fixed_range,
                      public_interface => $public_interface,
                      flat_interface   => $private_interface
      }
      $resource_parameters = merge($config_overrides, $parameters)
      $flat_resource = {'nova::network::flat' => $resource_parameters }
      create_resources('class', $flat_resource)
    }
    'nova.network.manager.VlanManager': {
      $parameters = { fixed_range      => $fixed_range,
                      public_interface => $public_interface,
                      vlan_interface   => $private_interface
      }
      $resource_parameters = merge($config_overrides, $parameters)
      $vlan_resource = { 'nova::network::vlan' => $resource_parameters }
      create_resources('class', $vlan_resource)
    }
    # I don't think this is applicable to Folsom...
    # If it is, the details will need changed. -jt
    'nova.network.quantum.manager.QuantumManager': {
      $parameters = { fixed_range      => $fixed_range,
                      public_interface => $public_interface,
                    }
      $resource_parameters = merge($config_overrides, $parameters)
      $quantum_resource = { 'nova::network::quantum' => $resource_parameters }
      create_resources('class', $quantum_resource)
    }
    default: {
      fail("Unsupported network manager: ${nova::network_manager} The supported network managers are nova.network.manager.FlatManager, nova.network.FlatDHCPManager and nova.network.manager.VlanManager")
    }
  }

}
