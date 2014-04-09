# == Class: nova::network::flatdhcp
#
# Configures nova-network with flat dhcp option
#
# === Parameters:
#
# [*fixed_range*]
#   (required) The IPv4 CIDR for the flat network
#
# [*flat_interface*]
#   (optional) FlatDHCP will bridge into this interface
#   Defaults to undef
#
# [*public_interface*]
#   (optional)
#   Defaults to undef
#
# [*flat_network_bridge*]
#   (optional) Bridge for simple network instances (
#   Defaults to 'br100'
#
# [*force_dhcp_release*]
#   (optional) Send a dhcp release on instance termination
#   Defaults to true
#
# [*flat_injected*]
#   (optional) Whether to attempt to inject network setup into guest
#   Defaults to false
#
# [*dhcp_domain*]
#   (optional) domain to use for building the hostnames
#   Defaults to 'novalocal'
#
# [*dhcpbridge*]
#   (optional) 'location of nova-dhcpbridge'
#   Defaults to '/usr/bin/nova-dhcpbridge'
#
# [*dhcpbridge_flagfile*]
#   (optional) location of flagfiles for dhcpbridge
#   Defaults to '/etc/nova/nova.conf
#
class nova::network::flatdhcp (
  $fixed_range,
  $flat_interface      = undef,
  $public_interface    = undef,
  $flat_network_bridge = 'br100',
  $force_dhcp_release  = true,
  $flat_injected       = false,
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
    'DEFAULT/network_manager':     value => 'nova.network.manager.FlatDHCPManager';
    'DEFAULT/fixed_range':         value => $fixed_range;
    'DEFAULT/flat_interface':      value => $flat_interface;
    'DEFAULT/flat_network_bridge': value => $flat_network_bridge;
    'DEFAULT/force_dhcp_release':  value => $force_dhcp_release;
    'DEFAULT/flat_injected':       value => $flat_injected;
    'DEFAULT/dhcp_domain':         value => $dhcp_domain;
    'DEFAULT/dhcpbridge':          value => $dhcpbridge;
    'DEFAULT/dhcpbridge_flagfile': value => $dhcpbridge_flagfile;
  }

}
