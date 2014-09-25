# == Class: neutron::plugins::linuxbridge
#
# Setups linuxbridge plugin for neutron server.
#
# === Parameters
#
# [*sql_connection*]
#   sql_connection is no longer configured in the plugin.ini.
#   Use $connection in the nuetron::server class to configure the SQL
#   connection string.
#
# [*network_vlan_ranges*]
#   (required) Comma-separated list of <physical_network>[:<vlan_min>:<vlan_max>]
#   tuples enumerating ranges of VLAN IDs on named physical networks that are
#   available for allocation.
#
# [*tenant_network_type*]
#   (optional) Type of network to allocate for tenant networks.
#   Defaults to 'vlan'.
#
# [*package_ensure*]
#   (optional) Ensure state for package. Defaults to 'present'.
#
class neutron::plugins::linuxbridge (
  $sql_connection      = false,
  $network_vlan_ranges = 'physnet1:1000:2000',
  $tenant_network_type = 'vlan',
  $package_ensure      = 'present'
) {

  include neutron::params

  Package['neutron'] -> Package['neutron-plugin-linuxbridge']
  Package['neutron-plugin-linuxbridge'] -> Neutron_plugin_linuxbridge<||>
  Neutron_plugin_linuxbridge<||> ~> Service<| title == 'neutron-server' |>
  Package['neutron-plugin-linuxbridge'] -> Service<| title == 'neutron-server' |>

  if $::operatingsystem == 'Ubuntu' {
    file_line { '/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG':
      path    => '/etc/default/neutron-server',
      match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
      line    => "NEUTRON_PLUGIN_CONFIG=${::neutron::params::linuxbridge_config_file}",
      require => [
        Package['neutron-plugin-linuxbridge'],
        Package['neutron-server'],
      ],
      notify  => Service['neutron-server'],
    }
  }

  package { 'neutron-plugin-linuxbridge':
    ensure => $package_ensure,
    name   => $::neutron::params::linuxbridge_server_package,
  }

  if $sql_connection {
    warning('sql_connection is deprecated for connection in the neutron::server class')
  }

  neutron_plugin_linuxbridge {
    'VLANS/tenant_network_type': value => $tenant_network_type;
    'VLANS/network_vlan_ranges': value => $network_vlan_ranges;
  }

  # In RH, this link is used to start Neutron process but in Debian, it's used only
  # to manage database synchronization.
  file {'/etc/neutron/plugin.ini':
    ensure  => link,
    target  => '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini',
    require => Package['neutron-plugin-linuxbridge']
  }

}
