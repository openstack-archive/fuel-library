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
  $ovs_modname   = 'openvswitch'
){
  include ::l23network::params

  if $use_ovs {
    $ovs_mod_ensure = present
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
  } else {
    $ovs_mod_ensure = absent
  }

  @k_mod{$ovs_modname:
    ensure => $ovs_mod_ensure
  }

  if $use_lnx {
    $mod_8021q_ensure = present
    $mod_bonding_ensure = present
    $mod_bridge_ensure = present
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
  } else {
    $mod_8021q_ensure = absent
    $mod_bonding_ensure = absent
    $mod_bridge_ensure = absent
  }

  @k_mod{'8021q':
    ensure => $mod_8021q_ensure
  }
  @k_mod{'bonding':
    ensure => $mod_bonding_ensure
  }
  @k_mod{'bridge':
    ensure => $mod_bridge_ensure
  }

  if $::l23network::params::lnx_ethernet_tools {
    ensure_packages($::l23network::params::lnx_ethernet_tools)
    Package[$::l23network::params::lnx_ethernet_tools] -> Anchor['l23network::l2::init']
  }

  anchor { 'l23network::l2::init': }

}
