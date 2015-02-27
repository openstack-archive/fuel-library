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
    Service['openvswitch-service'] -> L23network::L3::Ifconfig<||>
    if !defined(Service['openvswitch-service']) {
      notify{ "Module ${module_name} cannot notify service openvswitch-service on packages update": }
    }
  }

  if $use_lnx {
    if $install_brctl {
      if !defined(Package["$l23network::params::lnx_bridge_tools"]) {
        package {"$l23network::params::lnx_bridge_tools": }
      }
    }
  }

  if $::osfamily =~ /(?i)debian/ {
    if !defined(Package["$l23network::params::lnx_bond_tools"]) {
      package {"$l23network::params::lnx_bond_tools": }
    }
  }

  if !defined(Package["$l23network::params::lnx_vlan_tools"]) {
    package {"$l23network::params::lnx_vlan_tools": }
  }

  if !defined(Package["$l23network::params::lnx_ethernet_tools"]) {
    package {"$l23network::params::lnx_ethernet_tools": }
  }

  if $::osfamily =~ /(?i)debian/ {
    Package["$l23network::params::lnx_bond_tools"] -> L23network::L3::Ifconfig<||>
  }
  Package["$l23network::params::lnx_vlan_tools"] -> L23network::L3::Ifconfig<||>
  Package["$l23network::params::lnx_ethernet_tools"] -> L23network::L3::Ifconfig<||>

}
