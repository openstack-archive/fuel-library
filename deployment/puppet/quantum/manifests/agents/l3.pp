#
class quantum::agents::l3 (
  $quantum_config     = {},
  $verbose          = 'False',
  $debug            = 'False',
  $create_networks  = true,               # ?????????????????
  $interface_driver = 'quantum.agent.linux.interface.OVSInterfaceDriver',
  $service_provider = 'generic'
) {
  include 'quantum::params'

  anchor {'quantum-l3': }
  Service<| title=='quantum-server' |> -> Anchor['quantum-l3']
  if $::operatingsystem == 'Ubuntu' {
    if $service_provider == 'pacemaker' {
       file { "/etc/init/quantum-l3-agent.override":
         replace => "no",
         ensure  => "present",
         content => "manual",
         mode    => 644,
         before  => Package['quantum-l3'],
       }
     }
  }

  if $::quantum::params::l3_agent_package {
    $l3_agent_package = 'quantum-l3'

    package { 'quantum-l3':
      name   => $::quantum::params::l3_agent_package,
      ensure => present,
    }
    # do not move it to outside this IF
    Package['quantum-l3'] -> Quantum_l3_agent_config <| |>
  } else {
    $l3_agent_package = $::quantum::params::package_name
  }

  include 'quantum::waist_setup'

  Quantum_config <| |> -> Quantum_l3_agent_config <| |>
  Quantum_l3_agent_config <| |> -> Service['quantum-l3']
  # Quantum_l3_agent_config <| |> -> Quantum_router <| |>
  # Quantum_l3_agent_config <| |> -> Quantum_net <| |>
  # Quantum_l3_agent_config <| |> -> Quantum_subnet <| |>

  quantum_l3_agent_config {
    'DEFAULT/debug':          value => $debug;
    'DEFAULT/verbose':        value => $verbose;
    'DEFAULT/root_helper':    value => $quantum_config['root_helper'];
    'DEFAULT/auth_url':       value => $quantum_config['keystone']['auth_url'];
    'DEFAULT/admin_user':     value => $quantum_config['keystone']['admin_user'];
    'DEFAULT/admin_password': value => $quantum_config['keystone']['admin_password'];
    'DEFAULT/admin_tenant_name': value => $quantum_config['keystone']['admin_tenant_name'];
    'DEFAULT/metadata_ip':   value => $quantum_config['metadata']['metadata_ip'];
    'DEFAULT/metadata_port': value => $quantum_config['metadata']['metadata_port'];
    'DEFAULT/use_namespaces': value => $quantum_config['L3']['use_namespaces'];
    'DEFAULT/send_arp_for_ha': value => $quantum_config['L3']['send_arp_for_ha'];
    'DEFAULT/periodic_interval': value => $quantum_config['L3']['resync_interval'];
    'DEFAULT/periodic_fuzzy_delay': value => $quantum_config['L3']['resync_fuzzy_delay'];
    'DEFAULT/external_network_bridge': value => $quantum_config['L3']['public_bridge'];
  }
  quantum_l3_agent_config{'DEFAULT/router_id': ensure => absent }

  Anchor['quantum-l3'] ->
    Quantum_l3_agent_config <| |> ->
      Exec<| title=='setup_router_id' |> ->
        #Exec<| title=='update_default_route_metric' |> ->
          Service<| title=='quantum-l3' |>  ->
            #Exec<| title=='settle-down-default-route' |> ->
              Anchor['quantum-l3-done']

  # rootwrap error with L3 agent
  # https://bugs.launchpad.net/quantum/+bug/1069966
  $iptables_manager = "/usr/lib/${::quantum::params::python_path}/quantum/agent/linux/iptables_manager.py"
  exec { 'patch-iptables-manager':
    command => "sed -i '272 s|/sbin/||' ${iptables_manager}",
    onlyif  => "sed -n '272p' ${iptables_manager} | grep -q '/sbin/'",
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    require => [Anchor['quantum-l3'], Package[$l3_agent_package]],
  }
  Service<| title == 'quantum-server' |> -> Service['quantum-l3']

  if $service_provider == 'pacemaker' {

    Service<| title == 'quantum-server' |> -> Cs_shadow['l3']
    Quantum_l3_agent_config <||> -> Cs_shadow['l3']

    # OCF script for pacemaker
    # and his dependences
    file {'quantum-l3-agent-ocf':
      path=>'/usr/lib/ocf/resource.d/mirantis/quantum-agent-l3',
      mode => 755,
      owner => root,
      group => root,
      source => "puppet:///modules/quantum/ocf/quantum-agent-l3",
    }
    Package['pacemaker'] -> File['quantum-l3-agent-ocf']
    File['quantum-l3-agent-ocf'] -> Cs_resource["p_${::quantum::params::l3_agent_service}"]
    File['q-agent-cleanup.py'] -> Cs_resource["p_${::quantum::params::l3_agent_service}"]

    cs_resource { "p_${::quantum::params::l3_agent_service}":
      ensure          => present,
      cib             => 'l3',
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'quantum-agent-l3',
      #require         => File['quantum-l3-agent'],
      parameters      => {
        'debug'       => $debug,
        'syslog'      => $::use_syslog,
        'os_auth_url' => $quantum_config['keystone']['auth_url'],
        'tenant'      => $quantum_config['keystone']['admin_tenant_name'],
        'username'    => $quantum_config['keystone']['admin_user'],
        'password'    => $quantum_config['keystone']['admin_password'],
      },
      operations      => {
        'monitor'  => {
          'interval' => '20',
          'timeout'  => '30'
        }
        ,
        'start'    => {
          'timeout' => '360'
        }
        ,
        'stop'     => {
          'timeout' => '360'
        }
      },
    }
    File<| title=='quantum-logging.conf' |> -> Cs_resource["p_${::quantum::params::l3_agent_service}"]
    Exec<| title=='setup_router_id' |> -> Cs_resource["p_${::quantum::params::l3_agent_service}"]

    cs_shadow { 'l3': cib => 'l3' }
    cs_commit { 'l3': cib => 'l3' }

    ###
    # Do not remember to be carefylly with Cs_shadow and Cs_commit orders.
    # at one time onli one Shadow can be without commit
    Cs_commit <| title == 'dhcp' |> -> Cs_shadow <| title == 'l3' |>
    Cs_commit <| title == 'ovs' |> -> Cs_shadow <| title == 'l3' |>
    Cs_commit <| title == 'quantum-metadata-agent' |> -> Cs_shadow <| title == 'l3' |>

    ::corosync::cleanup{"p_${::quantum::params::l3_agent_service}": }

    Cs_commit['l3'] -> ::Corosync::Cleanup["p_${::quantum::params::l3_agent_service}"]
    Cs_commit['l3'] ~> ::Corosync::Cleanup["p_${::quantum::params::l3_agent_service}"]
    ::Corosync::Cleanup["p_${::quantum::params::l3_agent_service}"] -> Service['quantum-l3']

    Cs_resource["p_${::quantum::params::l3_agent_service}"] -> Cs_colocation['l3-with-ovs']
    Cs_resource["p_${::quantum::params::l3_agent_service}"] -> Cs_order['l3-after-ovs']
    Cs_resource["p_${::quantum::params::l3_agent_service}"] -> Cs_colocation['l3-with-metadata']
    Cs_resource["p_${::quantum::params::l3_agent_service}"] -> Cs_order['l3-after-metadata']

    cs_colocation { 'l3-with-ovs':
      ensure     => present,
      cib        => 'l3',
      primitives => ["p_${::quantum::params::l3_agent_service}", "clone_p_${::quantum::params::ovs_agent_service}"],
      score      => 'INFINITY',
    } ->
    cs_order { 'l3-after-ovs':
      ensure => present,
      cib    => 'l3',
      first  => "clone_p_${::quantum::params::ovs_agent_service}",
      second => "p_${::quantum::params::l3_agent_service}",
      score  => 'INFINITY',
    } -> Service['quantum-l3']

    cs_colocation { 'l3-with-metadata':
      ensure     => present,
      cib        => 'l3',
      primitives => [
          "p_${::quantum::params::l3_agent_service}",
          "clone_p_quantum-metadata-agent"
      ],
      score      => 'INFINITY',
    } ->
    cs_order { 'l3-after-metadata':
      ensure => present,
      cib    => "l3",
      first  => "clone_p_quantum-metadata-agent",
      second => "p_${::quantum::params::l3_agent_service}",
      score  => 'INFINITY',
    } -> Service['quantum-l3']

    # start DHCP and L3 agents on different controllers if it's possible
    cs_colocation { 'dhcp-without-l3':
      ensure     => present,
      cib        => 'l3',
      score      => '-100',
      primitives => [
        "p_${::quantum::params::dhcp_agent_service}",
        "p_${::quantum::params::l3_agent_service}"
      ],
    }

    # Ensure service is stopped  and disabled by upstart/init/etc.
    Anchor['quantum-l3'] ->
      Service['quantum-l3-init_stopped'] ->
        Cs_resource["p_${::quantum::params::l3_agent_service}"] ->
          Service['quantum-l3'] ->
            Anchor['quantum-l3-done']

    service { 'quantum-l3-init_stopped':
      name       => "${::quantum::params::l3_agent_service}",
      enable     => false,
      ensure     => stopped,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::quantum::params::service_provider,
    }

    service { 'quantum-l3':
      name       => "p_${::quantum::params::l3_agent_service}",
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => false,
      provider   => "pacemaker",
    }

  } else {
    Quantum_config <| |> ~> Service['quantum-l3']
    Quantum_l3_agent_config <| |> ~> Service['quantum-l3']
    File<| title=='quantum-logging.conf' |> ->
    service { 'quantum-l3':
      name       => $::quantum::params::l3_agent_service,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::quantum::params::service_provider,
    }
  }

  anchor {'quantum-l3-cellar': }
  Anchor['quantum-l3-cellar'] -> Anchor['quantum-l3-done']
  anchor {'quantum-l3-done': }
  Anchor['quantum-l3'] -> Anchor['quantum-l3-done']

}

# vim: set ts=2 sw=2 et :
