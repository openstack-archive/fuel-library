# == Class: neutron::config
#
# This class is used to manage arbitrary Neutron configurations.
#
# === Parameters
#
# [*xxx_config*]
#   (optional) Allow configuration of arbitrary Neutron xxx specific configurations.
#   The value is an hash of neutron_config resources. Example:
#   server_config =>
#   { 'DEFAULT/foo' => { value => 'fooValue'},
#     'DEFAULT/bar' => { value => 'barValue'}
#   }
#
#   NOTE: { 'DEFAULT/foo': value => 'fooValue'; 'DEFAULT/bar': value => 'barValue'} is invalid.
#
#   In yaml format, Example:
#   server_config:
#     DEFAULT/foo:
#       value: fooValue
#     DEFAULT/bar:
#       value: barValue
#
# [**server_config**]
#   (optional) Manage configuration of neutron.conf
#
# [**api_config**]
#   (optional) Manage configuration of api-paste.ini
#
# [**l3_agent_config**]
#   (optional) Manage configuration of l3_agent.ini
#
# [**dhcp_agent_config**]
#   (optional) Manage configuration of dhcp_agent.ini
#
# [**lbaas_agent_config**]
#   (optional) Manage configuration of lbaas_agent.ini
#
# [**metadata_agent_config**]
#   (optional) Manage configuration of metadata_agent.ini
#
# [**metering_agent_config**]
#   (optional) Manage configuration of metering_agent.ini
#
# [**vpnaas_agent_config**]
#   (optional) Manage configuration of vpn_agent.ini
#
# [**plugin_linuxbridge_config**]
#   (optional) Manage configuration of linuxbridge_conf.ini
#
# [**plugin_cisco_db_conn_config**]
#   (optional) Manage configuration of plugins/cisco/db_conn.ini
#
# [**plugin_cisco_config**]
#   (optional) Manage configuration of cisco_plugins.ini
#
# [**plugin_ml2_config**]
#   (optional) Manage configuration of ml2_conf.ini
#
# [**plugin_ovs_config**]
#   (optional) Manage configuration of ovs_neutron_plugin.ini
#
#   NOTE: The configuration MUST NOT be already handled by this module
#   or Puppet catalog compilation will fail with duplicate resources.
#
class neutron::config (
  $server_config                 = {},
  $api_config                    = {},
  $l3_agent_config               = {},
  $dhcp_agent_config             = {},
  $lbaas_agent_config            = {},
  $metadata_agent_config         = {},
  $metering_agent_config         = {},
  $vpnaas_agent_config           = {},
  $plugin_linuxbridge_config     = {},
  $plugin_cisco_db_conn_config   = {},
  $plugin_cisco_l2network_config = {},
  $plugin_cisco_config           = {},
  $plugin_ml2_config             = {},
  $plugin_ovs_config             = {},
) {

  validate_hash($server_config)
  validate_hash($api_config)
  validate_hash($l3_agent_config)
  validate_hash($dhcp_agent_config)
  validate_hash($lbaas_agent_config)
  validate_hash($metadata_agent_config)
  validate_hash($metering_agent_config)
  validate_hash($vpnaas_agent_config)
  validate_hash($plugin_linuxbridge_config)
  validate_hash($plugin_cisco_db_conn_config)
  validate_hash($plugin_cisco_l2network_config)
  validate_hash($plugin_cisco_config)
  validate_hash($plugin_ml2_config)
  validate_hash($plugin_ovs_config)

  create_resources('neutron_config', $server_config)
  create_resources('neutron_api_config', $api_config)
  create_resources('neutron_l3_agent_config', $l3_agent_config)
  create_resources('neutron_dhcp_agent_config', $dhcp_agent_config)
  create_resources('neutron_metadata_agent_config', $metadata_agent_config)
  create_resources('neutron_metering_agent_config', $metering_agent_config)
  create_resources('neutron_vpnaas_agent_config', $vpnaas_agent_config)
  create_resources('neutron_plugin_linuxbridge', $plugin_linuxbridge_config)
  create_resources('neutron_plugin_cisco_db_conn', $plugin_cisco_db_conn_config)
  create_resources('neutron_plugin_cisco_l2network', $plugin_cisco_l2network_config)
  create_resources('neutron_plugin_cisco', $plugin_cisco_config)
  create_resources('neutron_plugin_ml2', $plugin_ml2_config)
  create_resources('neutron_plugin_ovs', $plugin_ovs_config)
}
