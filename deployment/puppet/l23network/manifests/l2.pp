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
    package {$::l23network::params::ovs_packages:
      ensure  => present,
      before  => Service['openvswitch-service'],
    } 
    service {'openvswitch-service':
      ensure    => running,
      name      => $::l23network::params::ovs_service_name,
      enable    => true,
      hasstatus => true,
      status    => $::l23network::params::ovs_status_cmd,
    }
  }

  if $::osfamily =~ /(?i)debian/ {
    if !defined(Package["$l23network::params::lnx_bond_tools"]) {
      package {"$l23network::params::lnx_bond_tools":
        ensure => installed
      }
    }
  }

  if !defined(Package["$l23network::params::lnx_vlan_tools"]) {
    package {"$l23network::params::lnx_vlan_tools":
      ensure => installed
    } 
  }

  if !defined(Package["$l23network::params::lnx_ethernet_tools"]) {
    package {"$l23network::params::lnx_ethernet_tools":
      ensure => installed
    }
  }

  if $use_ovs {
    if $::osfamily =~ /(?i)debian/ {
      Package["$l23network::params::lnx_bond_tools"] -> Service['openvswitch-service']
    }
    Package["$l23network::params::lnx_vlan_tools"] -> Service['openvswitch-service']
    Package["$l23network::params::lnx_ethernet_tools"] -> Service['openvswitch-service']
  }

}
