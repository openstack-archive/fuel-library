# == Class: neutron::agents::linuxbridge
#
# Setups linuxbridge neutron agent.
#
# === Parameters
#
# [*physical_interface_mappings*]
#   (required) Comma-separated list of <physical_network>:<physical_interface>
#   tuples mapping physical network names to agent's node-specific physical
#   network interfaces.
#
# [*firewall_driver*]
#   (optional) Firewall driver for realizing neutron security group function.
#   Defaults to 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver'.
#
# [*package_ensure*]
#   (optional) Ensure state for package. Defaults to 'present'.
#
# [*enable*]
#   (optional) Enable state for service. Defaults to 'true'.
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
class neutron::agents::linuxbridge (
  $physical_interface_mappings,
  $firewall_driver = 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver',
  $package_ensure  = 'present',
  $enable          = true,
  $manage_service  = true
) {

  include neutron::params

  Neutron_config<||>             ~> Service['neutron-plugin-linuxbridge-service']
  Neutron_plugin_linuxbridge<||> ~> Service<| title == 'neutron-plugin-linuxbridge-service' |>

  if $::neutron::params::linuxbridge_agent_package {
    Package['neutron'] -> Package['neutron-plugin-linuxbridge-agent']
    Package['neutron-plugin-linuxbridge-agent'] -> Neutron_plugin_linuxbridge<||>
    Package['neutron-plugin-linuxbridge-agent'] -> Service['neutron-plugin-linuxbridge-service']
    package { 'neutron-plugin-linuxbridge-agent':
      ensure => $package_ensure,
      name   => $::neutron::params::linuxbridge_agent_package,
    }
  } else {
    # Some platforms (RedHat) do not provide a separate neutron plugin
    # linuxbridge agent package. The configuration file for the linuxbridge
    # agent is provided by the neutron linuxbridge plugin package.
    Package['neutron-plugin-linuxbridge'] -> Neutron_plugin_linuxbridge<||>

    if ! defined(Package['neutron-plugin-linuxbridge']) {
      package { 'neutron-plugin-linuxbridge':
        ensure  => $package_ensure,
        name    => $::neutron::params::linuxbridge_server_package,
      }
    }
  }

  neutron_plugin_linuxbridge {
    'LINUX_BRIDGE/physical_interface_mappings': value => $physical_interface_mappings;
    'SECURITYGROUP/firewall_driver':            value => $firewall_driver;
  }

  if $manage_service {
    if $enable {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'neutron-plugin-linuxbridge-service':
    ensure  => $service_ensure,
    name    => $::neutron::params::linuxbridge_agent_service,
    enable  => $enable,
  }
}
