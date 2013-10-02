class quantum::agents::ovs (
  $package_ensure     = 'present',
  $enabled            = true,
  $bridge_uplinks     = ['br-ex:eth2'],
  $bridge_mappings    = ['physnet1:br-ex'],
  $integration_bridge = 'br-int',
  $enable_tunneling   = true,
  $local_ip           = undef,
  $tunnel_bridge      = 'br-tun',
  $service_provider   = 'generic') {
  include 'quantum::params'

  if $enable_tunneling and !$local_ip {
    fail('Local ip for ovs agent must be set when tunneling is enabled')
  }

  include 'quantum::waist_setup'

  if defined(Anchor['quantum-plugin-ovs-done']) {
    # install quantum-ovs-agent at the same host where 
    # quantum-server + quantum-ovs-plugin
    Anchor['quantum-plugin-ovs-done'] -> Anchor['quantum-ovs-agent']

  }

  if defined(Anchor['quantum-server-done']) {
    Anchor['quantum-server-done'] -> Anchor['quantum-ovs-agent']
  }

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
    }
  }

  if $::quantum::params::ovs_agent_package {
    Package['quantum'] -> Package['quantum-plugin-ovs-agent']

    $ovs_agent_package = 'quantum-plugin-ovs-agent'

    package { 'quantum-plugin-ovs-agent':
      name   => $::quantum::params::ovs_agent_package,
      ensure => $package_ensure,
    }
  } else {
    $ovs_agent_package = $::quantum::params::ovs_server_package
  }

  if !defined(Anchor['quantum-server-done']) {
    # if defined -- this depends already defined
    Package[$ovs_agent_package] -> Quantum_plugin_ovs <| |>
  }

  l23network::l2::bridge { $integration_bridge:
    external_ids  => "bridge-id=${integration_bridge}",
    ensure        => present,
    skip_existing => true,
  }

  if $enable_tunneling {
    L23network::L2::Bridge<| |> ->
      Anchor['quantum-ovs-agent-done']
    l23network::l2::bridge { $tunnel_bridge:
      external_ids  => "bridge-id=${tunnel_bridge}",
      ensure        => present,
      skip_existing => true,
    } ->
    Anchor['quantum-ovs-agent-done']
    quantum_plugin_ovs { 'OVS/local_ip': value => $local_ip; }

  } else {
    L23network::L2::Bridge[$integration_bridge] ->
      Anchor['quantum-ovs-agent-done']
    quantum::plugins::ovs::bridge { $bridge_mappings: # Do not quote!!! may be array!
    } ->
    quantum::plugins::ovs::port { $bridge_uplinks: # Do not quote!!! may be array!
    } -> 
    Anchor['quantum-ovs-agent-done']
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  #Quantum_config <| |> ~> Service['quantum-ovs-agent']
  #Quantum_plugin_ovs <| |> ~> Service['quantum-ovs-agent']
  #Service <| title == 'quantum-server' |> -> Service['quantum-ovs-agent']

    if $service_provider == 'pacemaker' {
    Quantum_config <| |> -> Cs_shadow['ovs']
    Quantum_plugin_ovs <| |> -> Cs_shadow['ovs']
    L23network::L2::Bridge <| |> -> Cs_shadow['ovs']

    cs_shadow { 'ovs': cib => 'ovs' }
    cs_commit { 'ovs': cib => 'ovs' }

    ::corosync::cleanup { "p_${::quantum::params::ovs_agent_service}": }

    Cs_commit['ovs'] -> ::Corosync::Cleanup["p_${::quantum::params::ovs_agent_service}"]
    Cs_commit['ovs'] ~> ::Corosync::Cleanup["p_${::quantum::params::ovs_agent_service}"]
    ::Corosync::Cleanup["p_${::quantum::params::ovs_agent_service}"] -> Service['quantum-ovs-agent']

    File<| title=='quantum-logging.conf' |> ->
    cs_resource { "p_${::quantum::params::ovs_agent_service}":
      ensure          => present,
      cib             => 'ovs',
      primitive_class => 'ocf',
      provided_by     => 'pacemaker',
      primitive_type  => 'quantum-agent-ovs',
      require         => File['quantum-ovs-agent'] ,
      multistate_hash => {
        'type' => 'clone',
      },
      ms_metadata     => {
        'interleave' => 'true',
      },
      parameters      => {
      }
      ,
      operations      => {
        'monitor'  => {
          'interval' => '20',
          'timeout'  => '30'
        }
        ,
        'start'    => {
          'timeout' => '480'
        }
        ,
        'stop'     => {
          'timeout' => '480'
        }
      }
      ,
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
      enable     => $enabled,
      ensure     => $service_ensure,
      hasstatus  => true,
      hasrestart => false,
      provider   => $service_provider,
    }

  } else {
    service { 'quantum-ovs-agent':
      name       => $::quantum::params::ovs_agent_service,
      enable     => $enabled,
      ensure     => $service_ensure,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::quantum::params::service_provider,
    }
  }

  Class[quantum::waistline] -> Service['quantum-ovs-agent']

  #todo: This service must be disabled if Quantum-ovs-agent managed by pacemaker
  service { 'quantum-ovs-cleanup':
    name       => 'quantum-ovs-cleanup',
    enable     => $enabled,
    ensure     => false,  # !!! Warning !!!
    hasstatus  => false,  # !!! 'false' is not mistake
    hasrestart => false,  # !!! cleanup is simple script runnung once at OS boot
  }

  Anchor['quantum-ovs-agent'] -> 
    Service['quantum-ovs-agent'] ->       # it's not mistate!
      Service['quantum-ovs-cleanup'] ->   # cleanup service after agent.
        Anchor['quantum-ovs-agent-done']

  anchor{'quantum-ovs-agent-done': }

  Anchor['quantum-ovs-agent-done'] -> Anchor<| title=='quantum-l3' |>
  Anchor['quantum-ovs-agent-done'] -> Anchor<| title=='quantum-dhcp-agent' |>

}
#
###
