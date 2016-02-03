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
# [*modprobe_bridge*]
#   (optional) Load kernel module bridge
#   Defaults to true
#
# [*modprobe_8021q*]
#   (optional) Load kernel module 8021q
#   Defaults to true
#
# [*modprobe_bonding*]
#   (optional) Load kernel module bonding
#   Defaults to true
#
class l23network::l2 (
  $ensure_package               = 'present',
  $use_lnx                      = true,
  $use_ovs                      = false,
  $install_ovs                  = $use_ovs,
  $install_brtool               = $use_lnx,
  $modprobe_bridge              = $use_lnx,
  $install_bondtool             = $use_lnx,
  $modprobe_bonding             = $use_lnx,
  $install_vlantool             = $use_lnx,
  $modprobe_8021q               = $use_lnx,
  $install_ethtool              = $use_lnx,
  $ovs_module_name              = $::l23network::params::ovs_kern_module_name,
  $use_ovs_dkms_datapath_module = true,
  $ovs_datapath_package_name    = $::l23network::params::ovs_datapath_package_name,
  $ovs_common_package_name      = $::l23network::params::ovs_common_package_name,
){

  include ::stdlib
  include ::l23network::params

  if $use_ovs {
    $ovs_mod_ensure = present
    if $install_ovs {
      if $use_ovs_dkms_datapath_module {
        package { 'openvswitch-datapath':
          ensure => $ensure_package,
          name   => $ovs_datapath_package_name,
        }
        Package['openvswitch-datapath'] -> Service['openvswitch-service']
      }
      if $ovs_common_package_name {
        package { 'openvswitch-common':
          ensure => $ensure_package,
          name   => $ovs_common_package_name,
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

  if $install_vlantool and $::l23network::params::lnx_vlan_tools {
    ensure_packages($::l23network::params::lnx_vlan_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_vlan_tools] -> Anchor['l23network::l2::init']
  }

  if $modprobe_8021q {
    @k_mod{'8021q':
      ensure => present
    }
  }

  if $install_bondtool and $::l23network::params::lnx_bond_tools {
    ensure_packages($::l23network::params::lnx_bond_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_bond_tools] -> Anchor['l23network::l2::init']
  }

  if $modprobe_bonding {
    @k_mod{'bonding':
      ensure => present
    }
  }

  if $install_brtool and $::l23network::params::lnx_bridge_tools {
    ensure_packages($::l23network::params::lnx_bridge_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_bridge_tools] -> Anchor['l23network::l2::init']
  }

  if $modprobe_bridge {
    @k_mod{'bridge':
      ensure => present
    }
  }

  if $install_ethtool and $::l23network::params::lnx_ethernet_tools {
    ensure_packages($::l23network::params::lnx_ethernet_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_ethernet_tools] -> Anchor['l23network::l2::init']
  }

  anchor { 'l23network::l2::init': }

}
