# == Class: l23network::l2
#
# Module for configuring L2 network.
# Requirements, packages and services.
#
class l23network::l2 (
  $use_ovs       = true,
  $use_lnx       = true,
  $install_ovs   = true,
  $install_brctl = true,
){
  include ::l23network::params

  if $use_ovs {
    if $install_ovs {
      if $::l23network::params::ovs_datapath_package_name {
        package { 'openvswitch-datapath':
          name => $::l23network::params::ovs_datapath_package_name
        }
      }
      package { 'openvswitch-common':
        name => $::l23network::params::ovs_common_package_name
      }

      Package<| title=='openvswitch-datapath' |> -> Package['openvswitch-common']
      Package['openvswitch-common'] ~> Service['openvswitch-service']
    }
    service {'openvswitch-service':
      ensure    => running,
      name      => $::l23network::params::ovs_service_name,
      enable    => true,
      hasstatus => true,
      status    => $::l23network::params::ovs_status_cmd,
    }
    Service['openvswitch-service'] -> Anchor['l23network::l2::init']
  }

  if $use_lnx {
    if $install_brctl {
      ensure_packages($::l23network::params::lnx_bridge_tools)
      #Package[$::l23network::params::lnx_bridge_tools] -> Anchor['l23network::l2::init']
    }
    if $::l23network::params::lnx_bond_tools {
      ensure_packages($::l23network::params::lnx_bond_tools)
      Package[$::l23network::params::lnx_bond_tools] -> Anchor['l23network::l2::init']
    }
    ensure_packages($::l23network::params::lnx_vlan_tools)
    Package[$::l23network::params::lnx_vlan_tools] -> Anchor['l23network::l2::init']
  }

  if $::l23network::params::lnx_ethernet_tools {
    ensure_packages($::l23network::params::lnx_ethernet_tools)
    Package[$::l23network::params::lnx_ethernet_tools] -> Anchor['l23network::l2::init']
  }

  anchor { 'l23network::l2::init': }

}
