# == Class: nova::network
#
# Manages nova-network. Note that
# Nova-network is not receiving upstream patches any more
# and Neutron should be used in its place
#
# === Parameters:
#
# [*private_interface*]
#   (optional) Interface used by private network.
#   Defaults to undef
#
# [*fixed_range*]
#   (optional) Fixed private network range.
#   Defaults to '10.0.0.0/8'
#
# [*public_interface*]
#   (optional) Interface used to connect vms to public network.
#   Defaults to undef
#
# [*num_networks*]
#   (optional) Number of networks that fixed range network should be
#   split into.
#   Defaults to 1
#
# [*floating_range*]
#   (optional) Range of floating ip addresses to create.
#   Defaults to false
#
# [*enabled*]
#   (optional) Whether the network service should be enabled.
#   Defaults to false
#
# [*network_manager*]
#   (optional) The type of network manager to use.
#   Defaults to 'nova.network.manager.FlatDHCPManager'
#
# [*config_overrides*]
#   (optional) Additional parameters to pass to the network manager class
#   Defaults to {}
#
# [*create_networks*]
#   (optional) Whether actual nova networks should be created using
#   the fixed and floating ranges provided.
#   Defaults to true
#
# [*ensure_package*]
#   (optional) The state of the nova network package
#   Defaults to 'present'
#
# [*install_service*]
#   (optional) Whether to install and enable the service
#   Defaults to true
#
class nova::network(
  $private_interface = undef,
  $fixed_range       = '10.0.0.0/8',
  $public_interface  = undef,
  $num_networks      = 1,
  $network_size      = 255,
  $floating_range    = false,
  $enabled           = false,
  $network_manager   = 'nova.network.manager.FlatDHCPManager',
  $config_overrides  = {},
  $create_networks   = true,
  $ensure_package    = 'present',
  $install_service   = true,
  $nameservers       = ['8.8.8.8','8.8.4.4']
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
    nova_config { 'DEFAULT/floating_range':   value => $floating_range }
  }

  if has_key($config_overrides, 'vlan_start') {
    $vlan_start = $config_overrides['vlan_start']
  } else {
    $vlan_start = undef
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
      nameservers   => $nameservers,
      vlan_start    => $vlan_start,
    }
    if $floating_range {
      nova::manage::floating { 'nova-vm-floating':
        network => $floating_range,
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
    default: {
      fail("Unsupported network manager: ${nova::network_manager} The supported network managers are nova.network.manager.FlatManager, nova.network.FlatDHCPManager and nova.network.manager.VlanManager")
    }
  }

}
