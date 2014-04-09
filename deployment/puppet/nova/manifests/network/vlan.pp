# == Class: nova::network::vlan
#
# Configures nova network to use vlans
#
# === Parameters:
#
# [*fixed_range*]
#   (required) IPv4 CIDR of the network
#
# [*vlan_interface*]
#   (required) Physical ethernet adapter name for vlan networking
#
# [*public_interface*]
#   (optional) Interface for public traffic
#   Defaults to undef
#
# [*vlan_start*]
#   (optional) First vlan to use
#   Defaults to '300'
#
# [*force_dhcp_release*]
#   (optional) Whether to send a dhcp release on instance termination
#   Defaults to true
#
# [*dhcp_domain*]
#   (optional) Domain to use for building the hostnames
#   Defaults to 'novalocal'
#
# [*dhcpbridge*]
#   (optional) location of nova-dhcpbridge
#   Defaults to '/usr/bin/nova-dhcpbridge'
#
# [*dhcpbridge_flagfile*]
#   (optional) location of flagfiles for dhcpbridge
#   Defaults to '/etc/nova/nova.conf'
#
class nova::network::vlan (
  $fixed_range,
  $vlan_interface,
  $public_interface    = undef,
  $vlan_start          = '300',
  $force_dhcp_release  = true,
  $dhcp_domain         = 'novalocal',
  $dhcpbridge          = '/usr/bin/nova-dhcpbridge',
  $dhcpbridge_flagfile = '/etc/nova/nova.conf'
) {

  if $::osfamily == 'RedHat' and $::operatingsystem != 'Fedora' {
    package { 'dnsmasq-utils': ensure => present }
  }

  if $public_interface {
    nova_config { 'DEFAULT/public_interface': value => $public_interface }
  }

  nova_config {
    'DEFAULT/network_manager':     value => 'nova.network.manager.VlanManager';
    'DEFAULT/fixed_range':         value => $fixed_range;
    'DEFAULT/vlan_interface':      value => $vlan_interface;
    'DEFAULT/vlan_start':          value => $vlan_start;
    'DEFAULT/force_dhcp_release':  value => $force_dhcp_release;
    'DEFAULT/dhcp_domain':         value => $dhcp_domain;
    'DEFAULT/dhcpbridge':          value => $dhcpbridge;
    'DEFAULT/dhcpbridge_flagfile': value => $dhcpbridge_flagfile;
  }

}
