# == Class: l23network::l2
#
# Module for configuring L2 network.
# Requirements, packages and services.
#
# === Parameters
#
# [*ensure_package*]
#   (optional) The state of used packages
#   Defaults to 'present'
#
class l23network::l2 (
  $ensure_package               = 'present',
  $use_lnx                      = true,
  $use_ovs                      = false,
  $install_ovs                  = $use_ovs,
  $install_brtool               = $use_lnx,
  $install_ethtool              = $use_lnx,
  $install_bondtool             = $use_lnx,
  $install_vlantool             = $use_lnx,
  $ovs_module_name              = $::l23network::params::ovs_kern_module_name,
  $use_ovs_dkms_datapath_module = true,
  $ovs_datapath_package_name    = $::l23network::params::ovs_datapath_package_name,
  $ovs_common_package_name      = $::l23network::params::ovs_common_package_name,
){
  include stdlib
  include ::l23network::params

  if $use_ovs {
    $ovs_mod_ensure = present
    if $install_ovs {
      if $use_ovs_dkms_datapath_module {
        package { 'openvswitch-datapath':
          name   => $ovs_datapath_package_name,
          ensure => $ensure_package,
        }
        Package['openvswitch-datapath'] -> Service['openvswitch-service']
      }
      if $ovs_common_package_name {
        package { 'openvswitch-common':
          name   => $ovs_common_package_name,
          ensure => $ensure_package,
        }
        Package['openvswitch-common'] ~> Service['openvswitch-service']
      }

      Package<| title=='openvswitch-datapath' |> -> Package<| title=='openvswitch-common' |>
    }

    service {'openvswitch-service':
      ensure    => 'running',
      name      => $::l23network::params::ovs_service_name,
      enable    => true,
      hasstatus => true,
    }
    Service['openvswitch-service'] -> Anchor['l23network::l2::init']

  } else {
    $ovs_mod_ensure = absent
  }

  @k_mod{$ovs_module_name :
    ensure => $ovs_mod_ensure
  }

  if $use_lnx {
    $mod_8021q_ensure = present
    $mod_bonding_ensure = present
    $mod_bridge_ensure = present
  } else {
    $mod_8021q_ensure = absent
    $mod_bonding_ensure = absent
    $mod_bridge_ensure = absent
  }

  if $install_vlantool and $::l23network::params::lnx_vlan_tools {
    ensure_packages($::l23network::params::lnx_vlan_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_vlan_tools] -> Anchor['l23network::l2::init']
  }
  @k_mod{'8021q':
    ensure => $mod_8021q_ensure
  }

  if $install_bondtool and $::l23network::params::lnx_bond_tools {
    ensure_packages($::l23network::params::lnx_bond_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_bond_tools] -> Anchor['l23network::l2::init']
  }
  @k_mod{'bonding':
    ensure => $mod_bonding_ensure
  }

  if $install_brtool and $::l23network::params::lnx_bridge_tools {
    ensure_packages($::l23network::params::lnx_bridge_tools, {
      'ensure' => $ensure_package,
    })
    #Package[$::l23network::params::lnx_bridge_tools] -> Anchor['l23network::l2::init']
  }
  @k_mod{'bridge':
    ensure => $mod_bridge_ensure
  }

  if $install_ethtool and $::l23network::params::lnx_ethernet_tools {
    ensure_packages($::l23network::params::lnx_ethernet_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_ethernet_tools] -> Anchor['l23network::l2::init']
  }

  anchor { 'l23network::l2::init': }

}
