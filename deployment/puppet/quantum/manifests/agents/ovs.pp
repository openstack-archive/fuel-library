class quantum::agents::ovs (
  $package_ensure     = 'present',
  $enabled            = true,
  $bridge_uplinks     = ['br-ex:eth2'],
  $bridge_mappings    = [
    'physnet1:br-ex'],
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

  Package[$ovs_agent_package] -> Quantum_plugin_ovs <| |>

  l23network::l2::bridge { $integration_bridge:
    external_ids  => "bridge-id=${integration_bridge}",
    ensure        => present,
    skip_existing => true,
  # require      => Service['quantum-plugin-ovs-service'],
  }

  if $enable_tunneling {
    l23network::l2::bridge { $tunnel_bridge:
      external_ids  => "bridge-id=${tunnel_bridge}",
      ensure        => present,
      skip_existing => true,
    # require      => Service['quantum-plugin-ovs-service'],
    }

    quantum_plugin_ovs { 'OVS/local_ip': value => $local_ip; }
  } else {
    quantum::plugins::ovs::bridge { $bridge_mappings: # require      => Service['quantum-plugin-ovs-service'],
     }

    quantum::plugins::ovs::port { $bridge_uplinks: # require      => Service['quantum-plugin-ovs-service'],
     }
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Quantum_config <| |> ~> Service['quantum-plugin-ovs-service']
  Quantum_plugin_ovs <| |> ~> Service['quantum-plugin-ovs-service']
  Service <| title == 'quantum-server' |> -> Service['quantum-plugin-ovs-service']

  L23network::L2::Bridge <| |> -> Service['quantum-plugin-ovs-service']

  if $service_provider == 'pacemaker' {
    Quantum_config <| |> -> Cs_shadow['ovs']
    Quantum_plugin_ovs <| |> -> Cs_shadow['ovs']
    L23network::L2::Bridge <| |> -> Cs_shadow['ovs']

    cs_shadow { 'ovs': cib => 'ovs' }

    cs_commit { 'ovs': cib => 'ovs' }

    Cs_commit['ovs'] -> Service['quantum-plugin-ovs-service']

    ::corosync::cleanup { "p_${::quantum::params::ovs_agent_service}": }

    Cs_commit['ovs'] -> ::Corosync::Cleanup["p_${::quantum::params::ovs_agent_service}"]
    Cs_commit['ovs'] ~> ::Corosync::Cleanup["p_${::quantum::params::ovs_agent_service}"]
    ::Corosync::Cleanup["p_${::quantum::params::ovs_agent_service}"] -> Service['quantum-plugin-ovs-service']

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
    service { 'quantum-ovs-agent-service_stopped':
      name       => $::quantum::params::ovs_agent_service,
      enable     => false,
      hasstatus  => false,
    }
    exec { 'quantum-ovs-agent-service_stopped':
      #todo: rewrite as script, that returns zero or wait, when it can return zero
      name   => "bash -c \"service ${::quantum::params::ovs_agent_service} stop || ( kill `pgrep -f quantum-openvswitch-agent` || : )\"",
      onlyif => "service ${::quantum::params::ovs_agent_service} status | grep \'${started_status}\'",
      path   => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
      returns => [0,""]
    }
    Package[$ovs_agent_package] ->
      Service['quantum-ovs-agent-service_stopped'] ->
        Exec['quantum-ovs-agent-service_stopped'] ->
          Cs_resource["p_${::quantum::params::ovs_agent_service}"]

    service { 'quantum-plugin-ovs-service':
      name       => "p_${::quantum::params::ovs_agent_service}",
      enable     => $enabled,
      ensure     => $service_ensure,
      hasstatus  => true,
      hasrestart => false,
      provider   => $service_provider,
    }

  } else {
    service { 'quantum-plugin-ovs-service':
      name       => $::quantum::params::ovs_agent_service,
      enable     => $enabled,
      ensure     => $service_ensure,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::quantum::params::service_provider,
    }
  }
  Class[quantum::waistline] -> Service[quantum-plugin-ovs-service]
  Package[$ovs_agent_package] -> Service[quantum-plugin-ovs-service]

  service { 'quantum-ovs-agent-cleanup':
    name       => 'quantum-ovs-cleanup',
    enable     => $enabled,
    ensure     => false,
    hasstatus  => false,
    hasrestart => false,
  }
  Service['quantum-plugin-ovs-service'] -> Service['quantum-ovs-agent-cleanup']

}
