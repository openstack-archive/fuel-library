class neutron::agents::ovs (
  $neutron_config     = {},
  $service_provider   = 'generic'
  #$bridge_uplinks     = ['br-ex:eth2'],
  #$bridge_mappings    = ['physnet1:br-ex'],
  #$integration_bridge = 'br-int',
  #$enable_tunneling   = true,
) {

  include 'neutron::params'
  include 'neutron::waist_setup'

  if defined(Anchor['neutron-plugin-ovs-done']) {
    # install neutron-ovs-agent at the same host where
    # neutron-server + neutron-ovs-plugin
    Anchor['neutron-plugin-ovs-done'] -> Anchor['neutron-ovs-agent']

  }

  if defined(Anchor['neutron-server-done']) {
    Anchor['neutron-server-done'] -> Anchor['neutron-ovs-agent']
  }

  anchor {'neutron-ovs-agent': }

  if $::operatingsystem == 'Ubuntu' {
    if $service_provider == 'pacemaker' {
       file { "/etc/init/neutron-plugin-openvswitch-agent.override":
         replace => "no",
         ensure  => "present",
         content => "manual",
         mode    => 644,
         before  => Package['neutron-plugin-ovs-agent'],
      }
    }
  }

  if $::neutron::params::ovs_agent_package {
    Package['neutron'] -> Package['neutron-plugin-ovs-agent']

    $ovs_agent_package = 'neutron-plugin-ovs-agent'

    package { 'neutron-plugin-ovs-agent':
      name   => $::neutron::params::ovs_agent_package,
    }
  } else {
    $ovs_agent_package = $::neutron::params::ovs_server_package
  }

  if !defined(Anchor['neutron-server-done']) {
    # if defined -- this depends already defined
    Package[$ovs_agent_package] -> Neutron_plugin_ovs <| |>
  }

  l23network::l2::bridge { $neutron_config['L2']['integration_bridge']:
    external_ids  => "bridge-id=${neutron_config['L2']['integration_bridge']}",
    ensure        => present,
    skip_existing => true,
  }

  if $neutron_config['L2']['enable_tunneling'] {
      L23network::L2::Bridge<| |> ->
          Anchor['neutron-ovs-agent-done']
      l23network::l2::bridge { $neutron_config['L2']['tunnel_bridge']:
          external_ids  => "bridge-id=${neutron_config['L2']['tunnel_bridge']}",
          ensure        => present,
          skip_existing => true,
      } ->
      Anchor['neutron-ovs-agent-done']
      neutron_plugin_ovs { 'OVS/local_ip': value => $neutron_config['L2']['local_ip']; }
  } else {
      L23network::L2::Bridge[$neutron_config['L2']['integration_bridge']] ->
        Anchor['neutron-ovs-agent-done']
      neutron::agents::utils::bridges { $neutron_config['L2']['phys_bridges']: } ->
        Anchor['neutron-ovs-agent-done']
  }

  if $service_provider == 'pacemaker' {
    Neutron_config <| |> -> Cs_shadow['ovs']
    Neutron_plugin_ovs <| |> -> Cs_shadow['ovs']
    L23network::L2::Bridge <| |> -> Cs_shadow['ovs']

    cs_shadow { 'ovs': cib => 'ovs' }
    cs_commit { 'ovs': cib => 'ovs' }

    ::corosync::cleanup { "p_${::neutron::params::ovs_agent_service}": }

    Cs_commit['ovs'] -> ::Corosync::Cleanup["p_${::neutron::params::ovs_agent_service}"]
    Cs_commit['ovs'] ~> ::Corosync::Cleanup["p_${::neutron::params::ovs_agent_service}"]
    ::Corosync::Cleanup["p_${::neutron::params::ovs_agent_service}"] -> Service['neutron-ovs-agent']

    # OCF script for pacemaker
    # and his dependences
    file {'neutron-ovs-agent-ocf':
      path=>'/usr/lib/ocf/resource.d/mirantis/neutron-agent-ovs',
      mode => 755,
      owner => root,
      group => root,
      source => "puppet:///modules/neutron/ocf/neutron-agent-ovs",
    }
    File['neutron-ovs-agent-ocf'] -> Cs_resource["p_${::neutron::params::ovs_agent_service}"]

    File<| title=='neutron-logging.conf' |> ->
    cs_resource { "p_${::neutron::params::ovs_agent_service}":
      ensure          => present,
      cib             => 'ovs',
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'neutron-agent-ovs',
      multistate_hash => {
        'type' => 'clone',
      },
      ms_metadata     => {
        'interleave' => 'true',
      },
      parameters      => {
      },
      operations      => {
        'monitor'  => {
          'interval' => '20',
          'timeout'  => '30'
        },
        'start'    => {
          'timeout' => '480'
        },
        'stop'     => {
          'timeout' => '480'
        }
      },
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
    service { 'neutron-ovs-agent_stopped':
      name       => $::neutron::params::ovs_agent_service,
      enable     => false,
      ensure     => stopped,
      hasstatus  => false,
      hasrestart => false
    }

    if $::osfamily =~ /(?i)debian/ {
      exec { 'neutron-ovs-agent_stopped':
        #todo: rewrite as script, that returns zero or wait, when it can return zero
        name   => "bash -c \"service ${::neutron::params::ovs_agent_service} stop || ( kill `pgrep -f neutron-openvswitch-agent` || : )\"",
        onlyif => "service ${::neutron::params::ovs_agent_service} status | grep \'${started_status}\'",
        path   => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
        returns => [0,""]
      }
    }
    L23network::L2::Bridge<| |> ->
      Package[$ovs_agent_package] ->
        Service['neutron-ovs-agent_stopped'] ->
          Exec<| title=='neutron-ovs-agent_stopped' |> ->
            Cs_resource["p_${::neutron::params::ovs_agent_service}"] ->
              Service['neutron-ovs-agent']

    service { 'neutron-ovs-agent':
      name       => "p_${::neutron::params::ovs_agent_service}",
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => false,
      provider   => $service_provider,
    }

  } else {
    # NON-HA mode
    service { 'neutron-ovs-agent':
      name       => $::neutron::params::ovs_agent_service,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::neutron::params::service_provider,
    }
    Neutron_config<||> ~> Service['neutron-ovs-agent']
    Neutron_plugin_ovs<||> ~> Service['neutron-ovs-agent']
  }
  Neutron_config<||> -> Service['neutron-ovs-agent']
  Neutron_plugin_ovs<||> -> Service['neutron-ovs-agent']

  Class[neutron::waistline] -> Service['neutron-ovs-agent']

  #todo: This service must be disabled if Quantum-ovs-agent managed by pacemaker
  case $operatingsystem {
   'Ubuntu': {
      package { 'neutron-ovs-cleanup': }
      service { 'neutron-ovs-cleanup':
        name       => 'neutron-ovs-cleanup',
        enable     => true,
        ensure     => stopped,# !!! Warning !!!
        hasstatus  => false,  # !!! 'stopped' is not mistake
        hasrestart => false,  # !!! cleanup is simple script running once at OS boot
        provider   => $::neutron::params::service_provider,
        require    => Package['neutron-ovs-cleanup'],
      }
    }
    default: { 
      service { 'neutron-ovs-cleanup':
        name       => 'neutron-ovs-cleanup',
        enable     => true,
        ensure     => stopped,# !!! Warning !!!
        hasstatus  => false,  # !!! 'stopped' is not mistake
        hasrestart => false,  # !!! cleanup is simple script running once at OS boot
        provider   => $::neutron::params::service_provider,
      }
    }
  }
    Service['neutron-ovs-agent'] ->       # it's not mistate!
      Service['neutron-ovs-cleanup'] ->   # cleanup service after agent.
        Anchor['neutron-ovs-agent-done']

  Anchor['neutron-ovs-agent'] ->
    Service['neutron-ovs-agent'] ->
      Anchor['neutron-ovs-agent-done']

  anchor{'neutron-ovs-agent-done': }

  Anchor['neutron-ovs-agent-done'] -> Anchor<| title=='neutron-l3' |>
  Anchor['neutron-ovs-agent-done'] -> Anchor<| title=='neutron-dhcp-agent' |>

}
# vim: set ts=2 sw=2 et :
