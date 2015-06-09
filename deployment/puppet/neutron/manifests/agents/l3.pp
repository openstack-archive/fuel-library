# == Class: neutron::agents::l3
#
# Installs and configures the Neutron L3 service
#
# TODO: create ability to have multiple L3 services
#
# === Parameters
#
# [*package_ensure*]
#   (optional) The state of the package
#   Defaults to present
#
# [*enabled*]
#   (optional) The state of the service
#   Defaults to true
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*debug*]
#   (optional) Print debug info in logs
#   Defaults to false
#
# [*external_network_bridge*]
#   (optional) The name of the external bridge
#   Defaults to br-ex
#
# [*use_namespaces*]
#   (optional) Enable overlapping IPs / network namespaces
#   Defaults to false
#
# [*interface_driver*]
#   (optional) Driver to interface with neutron
#   Defaults to OVSInterfaceDriver
#
# [*router_id*]
#   (optional) The ID of the external router in neutron
#   Defaults to blank
#
# [*gateway_external_network_id*]
#   (optional) The ID of the external network in neutron
#   Defaults to blank
#
# [*handle_internal_only_routers*]
#   (optional) L3 Agent will handle non-external routers
#   Defaults to true
#
# [*metadata_port*]
#   (optional) The port of the metadata server
#   Defaults to 9697
#
# [*send_arp_for_ha*]
#   (optional) Send this many gratuitous ARPs for HA setup. Set it below or equal to 0
#   to disable this feature.
#   Defaults to 3
#
# [*periodic_interval*]
#   (optional) seconds between re-sync routers' data if needed
#   Defaults to 40
#
# [*periodic_fuzzy_delay*]
#   (optional) seconds to start to sync routers' data after starting agent
#   Defaults to 5
#
# [*enable_metadata_proxy*]
#   (optional) can be set to False if the Nova metadata server is not available
#   Defaults to True
#
# [*network_device_mtu*]
#   (optional) The MTU size for the interfaces managed by the L3 agent
#   Defaults to undef
#   Should be deprecated in the next major release in favor of a global parameter
#
# [*router_delete_namespaces*]
#   (optional) namespaces can be deleted cleanly on the host running the L3 agent
#   Defaults to False
#
# [*ha_enabled*]
#   (optional) Enabled or not HA for L3 agent.
#   Defaults to false
#
# [*ha_vrrp_auth_type*]
#   (optional) VRRP authentication type. Can be AH or PASS.
#   Defaults to "PASS"
#
# [*ha_vrrp_auth_password*]
#   (optional) VRRP authentication password. Required if ha_enabled = true.
#   Defaults to undef
#
# [*ha_vrrp_advert_int*]
#   (optional) The advertisement interval in seconds.
#   Defaults to '2'
#
# [*agent_mode*]
#   (optional) The working mode for the agent.
#   'legacy': default behavior (without DVR)
#   'dvr': enable DVR for an L3 agent running on compute node (DVR in production)
#   'dvr_snat': enable DVR with centralized SNAT support (DVR for single-host, for testing only)
#   Defaults to 'legacy'
#
# [*allow_automatic_l3agent_failover*]
#   (optional) Automatically reschedule routers from offline L3 agents to online
#   L3 agents.
#   This is another way to run virtual routers in highly available way but with slow
#   failover performances compared to Keepalived feature in Neutron L3 Agent.
#   Defaults to 'False'
#
class neutron::agents::l3 (
  $package_ensure                   = 'present',
  $enabled                          = true,
  $manage_service                   = true,
  $debug                            = false,
  $external_network_bridge          = 'br-ex',
  $use_namespaces                   = true,
  $interface_driver                 = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $router_id                        = undef,
  $gateway_external_network_id      = undef,
  $handle_internal_only_routers     = true,
  $metadata_port                    = '9697',
  $send_arp_for_ha                  = '3',
  $periodic_interval                = '40',
  $periodic_fuzzy_delay             = '5',
  $enable_metadata_proxy            = true,
  $network_device_mtu               = undef,
  $router_delete_namespaces         = false,
  $ha_enabled                       = false,
  $ha_vrrp_auth_type                = 'PASS',
  $ha_vrrp_auth_password            = undef,
  $ha_vrrp_advert_int               = '3',
  $agent_mode                       = 'legacy',
  $allow_automatic_l3agent_failover = false,
) {

  include neutron::params

  Neutron_config<||>          ~> Service['neutron-l3']
  Neutron_l3_agent_config<||> ~> Service['neutron-l3']

  if $ha_enabled {
    neutron_l3_agent_config {
      'DEFAULT/ha_vrrp_auth_type':     value => $ha_vrrp_auth_type;
      'DEFAULT/ha_vrrp_auth_password': value => $ha_vrrp_auth_password;
      'DEFAULT/ha_vrrp_advert_int':    value => $ha_vrrp_advert_int;
    }
  }

  neutron_l3_agent_config {
    'DEFAULT/debug':                            value => $debug;
    'DEFAULT/external_network_bridge':          value => $external_network_bridge;
    'DEFAULT/use_namespaces':                   value => $use_namespaces;
    'DEFAULT/interface_driver':                 value => $interface_driver;
    'DEFAULT/router_id':                        value => $router_id;
    'DEFAULT/gateway_external_network_id':      value => $gateway_external_network_id;
    'DEFAULT/handle_internal_only_routers':     value => $handle_internal_only_routers;
    'DEFAULT/metadata_port':                    value => $metadata_port;
    'DEFAULT/send_arp_for_ha':                  value => $send_arp_for_ha;
    'DEFAULT/periodic_interval':                value => $periodic_interval;
    'DEFAULT/periodic_fuzzy_delay':             value => $periodic_fuzzy_delay;
    'DEFAULT/enable_metadata_proxy':            value => $enable_metadata_proxy;
    'DEFAULT/router_delete_namespaces':         value => $router_delete_namespaces;
    'DEFAULT/agent_mode':                       value => $agent_mode;
    'DEFAULT/allow_automatic_l3agent_failover': value => $allow_automatic_l3agent_failover;
  }

  if $network_device_mtu {
    warning('The neutron::l3_agent::newtork_device_mtu parameter is deprecated, use neutron::newtork_device_mtu instead.')
    neutron_l3_agent_config {
      'DEFAULT/network_device_mtu':           value => $network_device_mtu;
    }
  } else {
    warning('The neutron::l3_agent::newtork_device_mtu parameter is deprecated, use neutron::newtork_device_mtu instead.')
    neutron_l3_agent_config {
      'DEFAULT/network_device_mtu':           ensure => absent;
    }
  }

  if $::neutron::params::l3_agent_package {
    Package['neutron-l3'] -> Neutron_l3_agent_config<||>
    package { 'neutron-l3':
      ensure  => $package_ensure,
      name    => $::neutron::params::l3_agent_package,
      require => Package['neutron'],
    }
  } else {
    # Some platforms (RedHat) does not provide a neutron L3 agent package.
    # The neutron L3 agent config file is provided by the neutron package.
    Package['neutron'] -> Neutron_l3_agent_config<||>
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'neutron-l3':
    ensure  => $service_ensure,
    name    => $::neutron::params::l3_agent_service,
    enable  => $enabled,
    require => Class['neutron'],
  }
}
