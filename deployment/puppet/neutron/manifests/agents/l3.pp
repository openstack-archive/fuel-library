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
class neutron::agents::l3 (
  $package_ensure               = 'present',
  $enabled                      = true,
  $manage_service               = true,
  $debug                        = false,
  $external_network_bridge      = 'br-ex',
  $use_namespaces               = true,
  $interface_driver             = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $router_id                    = undef,
  $gateway_external_network_id  = undef,
  $handle_internal_only_routers = true,
  $metadata_port                = '9697',
  $send_arp_for_ha              = '3',
  $periodic_interval            = '40',
  $periodic_fuzzy_delay         = '5',
  $enable_metadata_proxy        = true,
  $network_device_mtu           = undef,
  $router_delete_namespaces     = false
) {

  include neutron::params

  Neutron_config<||>          ~> Service['neutron-l3']
  Neutron_l3_agent_config<||> ~> Service['neutron-l3']

  neutron_l3_agent_config {
    'DEFAULT/debug':                        value => $debug;
    'DEFAULT/external_network_bridge':      value => $external_network_bridge;
    'DEFAULT/use_namespaces':               value => $use_namespaces;
    'DEFAULT/interface_driver':             value => $interface_driver;
    'DEFAULT/router_id':                    value => $router_id;
    'DEFAULT/gateway_external_network_id':  value => $gateway_external_network_id;
    'DEFAULT/handle_internal_only_routers': value => $handle_internal_only_routers;
    'DEFAULT/metadata_port':                value => $metadata_port;
    'DEFAULT/send_arp_for_ha':              value => $send_arp_for_ha;
    'DEFAULT/periodic_interval':            value => $periodic_interval;
    'DEFAULT/periodic_fuzzy_delay':         value => $periodic_fuzzy_delay;
    'DEFAULT/enable_metadata_proxy':        value => $enable_metadata_proxy;
    'DEFAULT/router_delete_namespaces':     value => $router_delete_namespaces;
  }
  Service<| title == 'neutron-server' |> -> Service['neutron-l3']

  if $service_provider == 'pacemaker' {

    # OCF script for pacemaker
    # and his dependences
    file {'neutron-l3-agent-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/neutron-agent-l3',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => "puppet:///modules/neutron/ocf/neutron-agent-l3",
    }

    Anchor['neutron-l3'] -> File['neutron-l3-agent-ocf']
    Neutron_l3_agent_config <| |> -> File['neutron-l3-agent-ocf']
    Package['pacemaker'] -> File['neutron-l3-agent-ocf']
    File<| title == 'ocf-mirantis-path' |> -> File['neutron-l3-agent-ocf']
    File<| title == 'q-agent-cleanup.py'|> -> File['neutron-l3-agent-ocf']
    Package[$l3_agent_package] -> File['neutron-l3-agent-ocf']

    if $primary_controller {
      cs_resource { "p_${::neutron::params::l3_agent_service}":
        ensure          => present,
        primitive_class => 'ocf',
        provided_by     => 'mirantis',
        primitive_type  => 'neutron-agent-l3',
        parameters      => {
          'debug'            => $debug,
          'syslog'           => $::use_syslog,
          'os_auth_url'      => $neutron_config['keystone']['auth_url'],
          'tenant'           => $neutron_config['keystone']['admin_tenant_name'],
          'username'         => $neutron_config['keystone']['admin_user'],
          'password'         => $neutron_config['keystone']['admin_password'],
          'amqp_server_port' => $neutron_config['amqp']['port'],
        },
        metadata        => { 'resource-stickiness' => '1' },
        operations      => {
          'monitor'  => {
            'interval' => '20',
            'timeout'  => '10'
          }
          ,
          'start'    => {
            'timeout' => '60'
          }
          ,
          'stop'     => {
            'timeout' => '60'
          }
        },
      }

      Cs_resource["p_${::neutron::params::l3_agent_service}"] ->
      cs_colocation { 'l3-with-ovs':
        ensure     => present,
        primitives => ["p_${::neutron::params::l3_agent_service}", "clone_p_${::neutron::params::ovs_agent_service}"],
        score      => 'INFINITY',
      } ->
      cs_order { 'l3-after-ovs':
        ensure => present,
        first  => "clone_p_${::neutron::params::ovs_agent_service}",
        second => "p_${::neutron::params::l3_agent_service}",
        score  => 'INFINITY',
      } -> Service['neutron-l3']

      Cs_resource["p_${::neutron::params::l3_agent_service}"] ->
      cs_colocation { 'l3-with-metadata':
        ensure     => present,
        primitives => [
            "p_${::neutron::params::l3_agent_service}",
            "clone_p_neutron-metadata-agent"
        ],
        score      => 'INFINITY',
      } ->
      cs_order { 'l3-after-metadata':
        ensure => present,
        first  => "clone_p_neutron-metadata-agent",
        second => "p_${::neutron::params::l3_agent_service}",
        score  => 'INFINITY',
      } -> Service['neutron-l3']

      # start DHCP and L3 agents on different controllers if it's possible
      Cs_resource["p_${::neutron::params::l3_agent_service}"] ->
      cs_colocation { 'dhcp-without-l3':
        ensure     => present,
        score      => '-100',
        primitives => [
          "p_${::neutron::params::dhcp_agent_service}",
          "p_${::neutron::params::l3_agent_service}"
        ],
      }

      Service['neutron-l3-init_stopped'] ->
        Cs_resource["p_${::neutron::params::l3_agent_service}"] ->
           Service['neutron-l3']

      File['neutron-l3-agent-ocf'] -> Cs_resource["p_${::neutron::params::l3_agent_service}"]
    } else {

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
