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
  $use_dpdk                     = false,
  $install_ovs                  = undef,
  $install_brtool               = undef,
  $install_dpdk                 = undef,
  $modprobe_bridge              = undef,
  $install_bondtool             = undef,
  $modprobe_bonding             = undef,
  $install_vlantool             = undef,
  $modprobe_8021q               = undef,
  $install_ethtool              = undef,
  $ovs_module_name              = $::l23network::params::ovs_kern_module_name,
  $use_ovs_dkms_datapath_module = true,
  $ovs_datapath_package_name    = $::l23network::params::ovs_datapath_package_name,
  $ovs_common_package_name      = $::l23network::params::ovs_common_package_name,
  $dpdk_options                 = {},
) inherits ::l23network::params {

  if $use_ovs {
    $ovs_mod_ensure = present
    $_install_ovs = pick($install_ovs, $use_ovs)

    if $_install_ovs {
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

    class { '::l23network::l2::dpdk':
      use_dpdk          => $use_dpdk,
      install_dpdk      => pick($install_dpdk, $use_dpdk),
      ovs_core_mask     => $dpdk_options['ovs_core_mask'],
      ovs_pmd_core_mask => $dpdk_options['ovs_pmd_core_mask'],
      ovs_socket_mem    => $dpdk_options['ovs_socket_mem'],
      install_ovs       => $_install_ovs,
      ensure_package    => $ensure_package,
    } -> Anchor['l23network::l2::init']

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

  if pick($install_vlantool, $use_lnx) and $::l23network::params::lnx_vlan_tools {
    ensure_packages($::l23network::params::lnx_vlan_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_vlan_tools] -> Anchor['l23network::l2::init']
  }

  if pick($modprobe_8021q, $use_lnx) {
    @k_mod{'8021q':
      ensure => present
    }
  }

  if pick($install_bondtool, $use_lnx) and $::l23network::params::lnx_bond_tools {
    ensure_packages($::l23network::params::lnx_bond_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_bond_tools] -> Anchor['l23network::l2::init']
  }

  if pick($modprobe_bonding, $use_lnx) {
    @k_mod{'bonding':
      ensure => present
    }
  }

  if pick($install_brtool, $use_lnx) and $::l23network::params::lnx_bridge_tools {
    ensure_packages($::l23network::params::lnx_bridge_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_bridge_tools] -> Anchor['l23network::l2::init']
  }

  if pick($modprobe_bridge, $use_lnx) {
    @k_mod{'bridge':
      ensure => present
    }
  }

  if pick($install_ethtool, $use_lnx) and $::l23network::params::lnx_ethernet_tools {
    ensure_packages($::l23network::params::lnx_ethernet_tools, {
      'ensure' => $ensure_package,
    })
    Package[$::l23network::params::lnx_ethernet_tools] -> Anchor['l23network::l2::init']
  }

  anchor { 'l23network::l2::init': }

}
