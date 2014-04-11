# == Class: l23network::l2
#
# Module for configuring L2 network.
# Requirements, packages and services.
#
class l23network::l2 (
  $use_ovs   = true,
  $use_lnxbr = true,
){
  include ::l23network::params

  if $use_ovs {
    #include ::l23network::l2::use_ovs
    if $::operatingsystem == 'Ubuntu' {
     package { 'openvswitch-datapath-lts-saucy-dkms': } ->
     Package[$::l23network::params::ovs_packages]
    }
    if $::operatingsystem == 'Centos' {
     package { 'kmod-openvswitch': } ->
     Package[$::l23network::params::ovs_packages]
    }
    package {$::l23network::params::ovs_packages: } ->
    service {'openvswitch-service':
      ensure    => running,
      name      => $::l23network::params::ovs_service_name,
      enable    => true,
      hasstatus => true,
      status    => $::l23network::params::ovs_status_cmd,
    }
    Service['openvswitch-service'] -> L23network::L3::Ifconfig<||>
    #FIXME(bogdando) assume ovs_packages has only 1 element, fix for many
    Package<|title == 'openvswitch-datapath-lts-raring-dkms' or
      title == $::l23network::params::ovs_packages[0] or
      title == 'kmod-openvswitch'|> ~>
    Service<| title == 'openvswitch-service'|>
    if !defined(Service['openvswitch-service']) {
      notify{ "Module ${module_name} cannot notify service openvswitch-service\
 on packages update": }
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
