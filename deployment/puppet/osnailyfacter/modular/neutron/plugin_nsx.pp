notice('MODULAR: plugin_nsx.pp')

$neutron_config = hiera('neutron_config')
$neutron_nsx_config = hiera('nsx_plugin')
$nodes = hiera('nodes')
$role = hiera('role')
$deployment_mode = hiera('deployment_mode')

###############################################

$connector_address = get_connector_address($nodes, $::fqdn, $neutron_nsx_config['nsx_controllers'])

if ($role == 'controller') or ($role == 'primary-controller') {
  class { 'plugin_neutronnsx::controller' :
    neutron_config     => $neutron_config,
    neutron_nsx_config => $neutron_nsx_config,
    connector_address  => $connector_address,
  }

  include neutron::params

  service { 'neutron-ovs-agent-service' :
    ensure  => 'stopped',
    name    => $neutron::params::ovs_agent_service,
    enable  => false,
  }

  service { 'neutron-l3' :
    ensure  => 'stopped',
    name    => $neutron::params::l3_agent_service,
    enable  => false,
  }

  if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {
    Service <| title == 'neutron-ovs-agent-service' |> {
      ensure => 'stopped',
      enable => true,
    }

    Service <| title == 'neutron-l3' |> {
      ensure => 'stopped',
      enable => true,
    }
  }

} elsif ($role == 'compute') {
  class { 'plugin_neutronnsx::compute' :
    neutron_nsx_config => $neutron_nsx_config,
    connector_address  => $connector_address,
  }
}
