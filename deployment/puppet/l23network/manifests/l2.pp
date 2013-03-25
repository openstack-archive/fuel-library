# == Class: l23network::l2
#
# Module for configuring L2 network.
# Requirements, packages and services.
#
class l23network::l2 {
  include ::l23network::params

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

  if $::osfamily =~ /(?i)debian/ and !defined(Package["$l23network::params::lnx_bond_tools"]) {
    package {"$l23network::params::lnx_bond_tools": 
      ensure => installed
    }
    Package["$l23network::params::lnx_bond_tools"] -> L23network::L3::Ifconfig<||>
  }

  if !defined(Package["$l23network::params::lnx_vlan_tools"]) {
    package {"$l23network::params::lnx_vlan_tools":
      ensure => installed
    } 
  }
  Package["$l23network::params::lnx_vlan_tools"] -> L23network::L3::Ifconfig<||>

  if !defined(Package["$l23network::params::lnx_ethernet_tools"]) {
    package {"$l23network::params::lnx_ethernet_tools":
      ensure => installed
    }
  }
  Package["$l23network::params::lnx_ethernet_tools"] -> L23network::L3::Ifconfig<||>

}
