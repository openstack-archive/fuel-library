class neutron::agents::ml2_agent (
  $neutron_config     = {},
  $ha_mode            = false,
  $primary_controller = false,
  $controller         = false
) {
  # Calculate "enabled" for HA
  include 'neutron::params'
  include 'neutron::waist_setup'

  $res_name = "p_${::neutron::params::ovs_agent_service}"

  Anchor<| title=='neutron-plugin-ml2-done' |> -> Anchor['neutron-ovs-agent']
  Anchor<| title=='neutron-server-done' |> -> Anchor['neutron-ovs-agent']
  Service<| title=='neutron-server' |> -> Anchor['neutron-ovs-agent']
  anchor {'neutron-ovs-agent': }  # OVS is not mistake!!!

  Neutron_config <| |> -> Neutron_plugin_ml2 <| |>

  tweaks::ubuntu_service_override {'neutron-ovs-agent-service':
    package_name => 'neutron-ovs-agent',
  }

  if $ha_mode {

    # OCF script for pacemaker
    # and his dependences
    file {'neutron-ovs-agent-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/neutron-agent-ovs',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => "puppet:///modules/neutron/ocf/neutron-agent-ovs",
    }
    File<| title == 'ocf-mirantis-path' |> -> File['neutron-ovs-agent-ocf']
    Anchor['neutron-ovs-agent'] -> File['neutron-ovs-agent-ocf']
    Neutron_plugin_ml2 <| |> -> File['neutron-ovs-agent-ocf']

    if $primary_controller {
      cs_resource { $res_name:
        ensure          => present,
        primitive_class => 'ocf',
        provided_by     => 'mirantis',
        primitive_type  => 'neutron-agent-ovs',
        multistate_hash => {
          'type' => 'clone',
        },
        ms_metadata     => {
          'interleave' => 'false',
        },
        parameters      => {
        },
        operations      => {
          'monitor'  => {
            'interval' => '20',
            'timeout'  => '10'
          },
          'start'    => {
            'timeout' => '80'
          },
          'stop'     => {
            'timeout' => '80'
          }
        },
      }

      File['neutron-ovs-agent-ocf'] ->
        Service['neutron-ovs-agent_stopped'] ->
          Cs_resource[$res_name] ->
            Service['neutron-ovs-agent-service']
      # this need because chain interrupted if selector not found
      Service['neutron-ovs-agent_stopped'] ->
        Exec<| title=='neutron-ovs-agent_stopped' |> ->
          Cs_resource[$res_name]
    } else {
      File['neutron-ovs-agent-ocf'] ->
        Service['neutron-ovs-agent_stopped'] ->
          Service['neutron-ovs-agent-service']
      # this need because chain interrupted if selector not found
      Service['neutron-ovs-agent_stopped'] ->
        Exec<| title=='neutron-ovs-agent_stopped' |> ->
          Service['neutron-ovs-agent-service']
    }

    # Prevent autostart ovs-agent system service
    $service_name = $res_name
    $service_provider = 'pacemaker'
    service { 'neutron-ovs-agent_stopped':
      name     => $::neutron::params::ovs_agent_service,
      ensure   => 'stopped',
      enable   => false,
    }
    case $::osfamily {
      /(?i)redhat/: {
        $started_status = "is running"
      }
      /(?i)debian/: {
        $started_status = "start/running"
      }
      default: { fail("The $::osfamily operating system is not supported.") }
    }
    if $::osfamily =~ /(?i)debian/ {
      # this exec needed because ovs-agent has no his own package
      # and located inside ovs-plugin package
      exec { 'neutron-ovs-agent_stopped':
        #todo: rewrite as script, that returns zero or wait, when it can return zero
        name   => "bash -c \"service ${::neutron::params::ovs_agent_service} stop || ( kill -9 `pgrep -f neutron-openvswitch-agent` || : )\"",
        onlyif => "service ${::neutron::params::ovs_agent_service} status | grep \'${started_status}\'",
        path   => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
        returns => [0,""]
      }
    }
  } else {
    $service_name = undef
    $service_provider = undef
  }

  if $controller {
    $firewall_driver = 'neutron.agent.firewall.NoopFirewallDriver'
  } else {
    $firewall_driver = undef
  }

  class {'neutron::agents::ml2::ovs':
    service_name          => $service_name,
    service_provider      => $service_provider,
    #bridge_uplinks        => split($neutron_config[L2][bridge_uplinks], ','),
    bridge_mappings       => split($neutron_config[L2][bridge_mappings], ','),
    integration_bridge    => $neutron_config[L2][integration_bridge],
    enable_tunneling      => $neutron_config[L2][enable_tunneling],
    tunnel_types          => split($neutron_config[L2][tunnel_types], ','),
    local_ip              => $neutron_config[L2][local_ip],
    tunnel_bridge         => $neutron_config[L2][tunnel_bridge],
    vxlan_udp_port        => $neutron_config[L2][vxlan_udp_port],
    polling_interval      => $neutron_config[polling_interval],
    firewall_driver       => $firewall_driver
    #$l2_population         = false,
    #$arp_responder         = false,
  }

  # RPM contains wrong (for ml2 mode) path to ovs plugin config file.
  # todo (sv): Check it for Ubuntu
  if $::osfamily =~ /(?i)redhat/ {
    file {'neutron-openvswitch-agent__sysconfig':
      path   =>'/etc/sysconfig/neutron-openvswitch-agent',
      mode   => '0644',
      owner  => root,
      group  => root,
      source => "puppet:///modules/neutron/neutron-openvswitch-agent.sysconfig",
    }
    Neutron_plugin_ml2<||> -> File['neutron-openvswitch-agent__sysconfig']
    File['neutron-openvswitch-agent__sysconfig'] -> Service['neutron-ovs-agent-service']
  }

  Service['neutron-ovs-agent-service'] -> Anchor['neutron-ovs-agent-done']

  anchor {'neutron-ovs-agent-done': }  # OVS!!!
}
###