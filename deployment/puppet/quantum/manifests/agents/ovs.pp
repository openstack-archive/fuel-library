class quantum::agents::ovs (
  $quantum_config     = {},
  $service_provider   = 'generic'
  #$bridge_uplinks     = ['br-ex:eth2'],
  #$bridge_mappings    = ['physnet1:br-ex'],
  #$integration_bridge = 'br-int',
  #$enable_tunneling   = true,
) {

  include 'quantum::params'
  include 'quantum::waist_setup'

  if defined(Anchor['quantum-plugin-ovs-done']) {
    # install quantum-ovs-agent at the same host where
    # quantum-server + quantum-ovs-plugin
    Anchor['quantum-plugin-ovs-done'] -> Anchor['quantum-ovs-agent']
  }

  Service<| title=='quantum-server' |> -> Anchor['quantum-ovs-agent']
  Quantum_config <| |> -> Quantum_plugin_ovs <| |>

  Anchor<| title=='quantum-server-done' |> ->
  anchor {'quantum-ovs-agent': }

  if $::operatingsystem == 'Ubuntu' {
    if $service_provider == 'pacemaker' {
       file { "/etc/init/quantum-plugin-openvswitch-agent.override":
         replace => "no",
         ensure  => "present",
         content => "manual",
         mode    => 644,
         before  => Package['quantum-plugin-ovs-agent'],
      }
    } else {
       file { '/etc/init/quantum-plugin-openvswitch-agent.override':
         replace => 'no',
         ensure  => 'present',
         content => 'manual',
         mode    => 644,
         before  => Package['quantum-plugin-ovs-agent'],
       }
       exec { 'rm-quantum-quantum-plugin-override':
         path      => '/sbin:/bin:/usr/bin:/usr/sbin',
         command   => "rm -f /etc/init/quantum-plugin-openvswitch-agent.override",
         require    => Package['quantum-plugin-ovs-agent'],
       }
     }
  }

  if $::quantum::params::ovs_agent_package {
    Package['quantum'] -> Package['quantum-plugin-ovs-agent']

    $ovs_agent_package = 'quantum-plugin-ovs-agent'

    package { 'quantum-plugin-ovs-agent':
      name   => $::quantum::params::ovs_agent_package,
    }
  } else {
    $ovs_agent_package = $::quantum::params::ovs_server_package
  }

  if !defined(Anchor['quantum-server-done']) {
    # if defined -- this depends already defined
    Package[$ovs_agent_package] -> Quantum_plugin_ovs <| |>
  }

  l23network::l2::bridge { $quantum_config['L2']['integration_bridge']:
    external_ids  => "bridge-id=${quantum_config['L2']['integration_bridge']}",
    ensure        => present,
    skip_existing => true,
  }

  if $quantum_config['L2']['enable_tunneling'] {
      L23network::L2::Bridge<| |> ->
          Anchor['quantum-ovs-agent-done']
      l23network::l2::bridge { $quantum_config['L2']['tunnel_bridge']:
          external_ids  => "bridge-id=${quantum_config['L2']['tunnel_bridge']}",
          ensure        => present,
          skip_existing => true,
      } ->
      Anchor['quantum-ovs-agent-done']
      quantum_plugin_ovs { 'OVS/local_ip': value => $quantum_config['L2']['local_ip']; }
  } else {
      L23network::L2::Bridge[$quantum_config['L2']['integration_bridge']] ->
        Anchor['quantum-ovs-agent-done']
      quantum::agents::utils::bridges { $quantum_config['L2']['phys_bridges']: } ->
        Anchor['quantum-ovs-agent-done']
  }

  #Quantum_config <| |> ~> Service['quantum-ovs-agent']
  #Quantum_plugin_ovs <| |> ~> Service['quantum-ovs-agent']
  #Service <| title == 'quantum-server' |> -> Service['quantum-ovs-agent']

  if $service_provider == 'pacemaker' {
    L23network::L2::Bridge <| |> -> Cs_shadow['ovs']
    Anchor['quantum-ovs-agent'] -> Cs_shadow['ovs']


    cs_shadow { 'ovs': cib => 'ovs' }
    cs_commit { 'ovs': cib => 'ovs' }

    corosync::cleanup { "clone_p_${::quantum::params::ovs_agent_service}": }

    Cs_commit['ovs'] ~> Corosync::Cleanup["clone_p_${::quantum::params::ovs_agent_service}"] -> Service['quantum-ovs-agent']

    # OCF script for pacemaker
    # and his dependences
    file {'quantum-ovs-agent-ocf':
      path=>'/usr/lib/ocf/resource.d/mirantis/quantum-agent-ovs',
      mode => 755,
      owner => root,
      group => root,
      source => "puppet:///modules/quantum/ocf/quantum-agent-ovs",
    }
    File<| title == 'ocf-mirantis-path' |> -> File['quantum-ovs-agent-ocf']
    Anchor['quantum-ovs-agent'] -> File['quantum-ovs-agent-ocf']
    Package[$ovs_agent_package] -> Quantum_plugin_ovs <| |> -> File['quantum-ovs-agent-ocf']
    File['quantum-ovs-agent-ocf'] -> Cs_resource["p_${::quantum::params::ovs_agent_service}"]

    cs_resource { "p_${::quantum::params::ovs_agent_service}":
      ensure          => present,
      cib             => 'ovs',
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'quantum-agent-ovs',
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
          'interval' => '30',
          'timeout'  => '10'
        },
        'start'    => {
          'timeout' => '120'
        },
        'stop'     => {
          'timeout' => '120'
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
    service { 'quantum-ovs-agent_stopped':
      name       => $::quantum::params::ovs_agent_service,
      enable     => false,
      ensure     => stopped,
      hasstatus  => false,
      hasrestart => false
    }

    if $::osfamily =~ /(?i)debian/ {
      exec { 'quantum-ovs-agent_stopped':
        #todo: rewrite as script, that returns zero or wait, when it can return zero
        name   => "bash -c \"service ${::quantum::params::ovs_agent_service} stop || ( kill `pgrep -f quantum-openvswitch-agent` || : )\"",
        onlyif => "service ${::quantum::params::ovs_agent_service} status | grep \'${started_status}\'",
        path   => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
        returns => [0,""]
      }
    }
    L23network::L2::Bridge<| |> ->
      Package[$ovs_agent_package] ->
        Service['quantum-ovs-agent_stopped'] ->
          Exec<| title=='quantum-ovs-agent_stopped' |> ->
            Cs_resource["p_${::quantum::params::ovs_agent_service}"] ->
              Service['quantum-ovs-agent']

    service { 'quantum-ovs-agent':
      name       => "p_${::quantum::params::ovs_agent_service}",
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => false,
      provider   => $service_provider,
    }

  } else {
    # NON-HA mode
    service { 'quantum-ovs-agent':
      name       => $::quantum::params::ovs_agent_service,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::quantum::params::service_provider,
    }
    Quantum_config<||> ~> Service['quantum-ovs-agent']
    Quantum_plugin_ovs<||> ~> Service['quantum-ovs-agent']
  }
  Quantum_config<||> -> Service['quantum-ovs-agent']
  Quantum_plugin_ovs<||> -> Service['quantum-ovs-agent']

  Class[quantum::waistline] -> Service['quantum-ovs-agent']

  #todo: This service must be disabled if Quantum-ovs-agent managed by pacemaker
  case $operatingsystem {
   'Ubuntu': {
      package { 'quantum-ovs-cleanup': }
      service { 'quantum-ovs-cleanup':
        name       => 'quantum-ovs-cleanup',
        enable     => true,
        ensure     => stopped,# !!! Warning !!!
        hasstatus  => false,  # !!! 'stopped' is not mistake
        hasrestart => false,  # !!! cleanup is simple script running once at OS boot
        provider   => $::quantum::params::service_provider,
        require    => Package['quantum-ovs-cleanup'],
      }
    }
    default: {
      service { 'quantum-ovs-cleanup':
        name       => 'quantum-ovs-cleanup',
        enable     => true,
        ensure     => stopped,# !!! Warning !!!
        hasstatus  => false,  # !!! 'stopped' is not mistake
        hasrestart => false,  # !!! cleanup is simple script running once at OS boot
        provider   => $::quantum::params::service_provider,
      }
    }
  }
    Service['quantum-ovs-agent'] ->       # it's not mistate!
      Service['quantum-ovs-cleanup'] ->   # cleanup service after agent.
        Anchor['quantum-ovs-agent-done']

  Anchor['quantum-ovs-agent'] ->
    Service['quantum-ovs-agent'] ->
      Anchor['quantum-ovs-agent-done']

  anchor{'quantum-ovs-agent-done': }

}
# vim: set ts=2 sw=2 et :
