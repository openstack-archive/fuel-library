#
class neutron::agents::l3 (
  $neutron_config     = {},
  $verbose          = 'False',
  $debug            = 'False',
  $create_networks  = true,               # ?????????????????
  $interface_driver = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $service_provider = 'generic'
) {
  include 'neutron::params'

  anchor {'neutron-l3': }
  Service<| title=='neutron-server' |> -> Anchor['neutron-l3']
  if $::operatingsystem == 'Ubuntu' {
    if $service_provider == 'pacemaker' {
       file { "/etc/init/neutron-l3-agent.override":
         replace => "no",
         ensure  => "present",
         content => "manual",
         mode    => 644,
         before  => Package['neutron-l3'],
       }
     }
  }

  if $::neutron::params::l3_agent_package {
    $l3_agent_package = 'neutron-l3'

    package { 'neutron-l3':
      name   => $::neutron::params::l3_agent_package,
      ensure => present,
    }
    # do not move it to outside this IF
    Package['neutron-l3'] -> Neutron_l3_agent_config <| |>
  } else {
    $l3_agent_package = $::neutron::params::package_name
  }

  include 'neutron::waist_setup'

  Neutron_config <| |> -> Neutron_l3_agent_config <| |>
  Neutron_l3_agent_config <| |> -> Service['neutron-l3']
  # Quantum_l3_agent_config <| |> -> Quantum_router <| |>
  # Quantum_l3_agent_config <| |> -> Quantum_net <| |>
  # Quantum_l3_agent_config <| |> -> Quantum_subnet <| |>

  neutron_l3_agent_config {
    'DEFAULT/debug':          value => $debug;
    'DEFAULT/verbose':        value => $verbose;
    'DEFAULT/root_helper':    value => $neutron_config['root_helper'];
    'DEFAULT/auth_url':       value => $neutron_config['keystone']['auth_url'];
    'DEFAULT/admin_user':     value => $neutron_config['keystone']['admin_user'];
    'DEFAULT/admin_password': value => $neutron_config['keystone']['admin_password'];
    'DEFAULT/admin_tenant_name': value => $neutron_config['keystone']['admin_tenant_name'];
    'DEFAULT/interface_driver':  value => $interface_driver;
    'DEFAULT/metadata_ip':   value => $neutron_config['metadata']['metadata_ip'];
    'DEFAULT/metadata_port': value => $neutron_config['metadata']['metadata_port'];
    'DEFAULT/use_namespaces': value => $neutron_config['L3']['use_namespaces'];
    'DEFAULT/send_arp_for_ha': value => $neutron_config['L3']['send_arp_for_ha'];
    'DEFAULT/periodic_interval': value => $neutron_config['L3']['resync_interval'];
    'DEFAULT/periodic_fuzzy_delay': value => $neutron_config['L3']['resync_fuzzy_delay'];
    'DEFAULT/external_network_bridge': value => $neutron_config['L3']['public_bridge'];
  }
  neutron_l3_agent_config{'DEFAULT/router_id': ensure => absent }

  Anchor['neutron-l3'] ->
    Neutron_l3_agent_config <| |> ->
      Exec<| title=='setup_router_id' |> ->
        #Exec<| title=='update_default_route_metric' |> ->
          Service<| title=='neutron-l3' |>  ->
            #Exec<| title=='settle-down-default-route' |> ->
              Anchor['neutron-l3-done']

  # rootwrap error with L3 agent
  # https://bugs.launchpad.net/neutron/+bug/1069966
  $iptables_manager = "/usr/lib/${::neutron::params::python_path}/neutron/agent/linux/iptables_manager.py"
  exec { 'patch-iptables-manager':
    command => "sed -i '272 s|/sbin/||' ${iptables_manager}",
    onlyif  => "sed -n '272p' ${iptables_manager} | grep -q '/sbin/'",
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    require => [Anchor['neutron-l3'], Package[$l3_agent_package]],
  }
  Service<| title == 'neutron-server' |> -> Service['neutron-l3']

  if $service_provider == 'pacemaker' {

    Service<| title == 'neutron-server' |> -> Cs_shadow['l3']
    Neutron_l3_agent_config <||> -> Cs_shadow['l3']

    # OCF script for pacemaker
    # and his dependences
    file {'neutron-l3-agent-ocf':
      path=>'/usr/lib/ocf/resource.d/mirantis/neutron-agent-l3',
      mode => 755,
      owner => root,
      group => root,
      source => "puppet:///modules/neutron/ocf/neutron-agent-l3",
    }
    Package['pacemaker'] -> File['neutron-l3-agent-ocf']
    File['neutron-l3-agent-ocf'] -> Cs_resource["p_${::neutron::params::l3_agent_service}"]
    File['q-agent-cleanup.py'] -> Cs_resource["p_${::neutron::params::l3_agent_service}"]

    cs_resource { "p_${::neutron::params::l3_agent_service}":
      ensure          => present,
      cib             => 'l3',
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'neutron-agent-l3',
      parameters      => {
        'debug'       => $debug,
        'syslog'      => $::use_syslog,
        'os_auth_url' => $neutron_config['keystone']['auth_url'],
        'tenant'      => $neutron_config['keystone']['admin_tenant_name'],
        'username'    => $neutron_config['keystone']['admin_user'],
        'password'    => $neutron_config['keystone']['admin_password'],
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
    File<| title=='neutron-logging.conf' |> -> Cs_resource["p_${::neutron::params::l3_agent_service}"]
    Exec<| title=='setup_router_id' |> -> Cs_resource["p_${::neutron::params::l3_agent_service}"]

    cs_shadow { 'l3': cib => 'l3' }
    cs_commit { 'l3': cib => 'l3' }

    ###
    # Do not remember to be carefylly with Cs_shadow and Cs_commit orders.
    # at one time onli one Shadow can be without commit
    Cs_commit <| title == 'dhcp' |> -> Cs_shadow <| title == 'l3' |>
    Cs_commit <| title == 'ovs' |> -> Cs_shadow <| title == 'l3' |>
    Cs_commit <| title == 'neutron-metadata-agent' |> -> Cs_shadow <| title == 'l3' |>

    ::corosync::cleanup{"p_${::neutron::params::l3_agent_service}": }

    Cs_commit['l3'] -> ::Corosync::Cleanup["p_${::neutron::params::l3_agent_service}"]
    Cs_commit['l3'] ~> ::Corosync::Cleanup["p_${::neutron::params::l3_agent_service}"]
    ::Corosync::Cleanup["p_${::neutron::params::l3_agent_service}"] -> Service['neutron-l3']

    Cs_resource["p_${::neutron::params::l3_agent_service}"] -> Cs_colocation['l3-with-ovs']
    Cs_resource["p_${::neutron::params::l3_agent_service}"] -> Cs_order['l3-after-ovs']
    Cs_resource["p_${::neutron::params::l3_agent_service}"] -> Cs_colocation['l3-with-metadata']
    Cs_resource["p_${::neutron::params::l3_agent_service}"] -> Cs_order['l3-after-metadata']

    cs_colocation { 'l3-with-ovs':
      ensure     => present,
      cib        => 'l3',
      primitives => ["p_${::neutron::params::l3_agent_service}", "clone_p_${::neutron::params::ovs_agent_service}"],
      score      => 'INFINITY',
    } ->
    cs_order { 'l3-after-ovs':
      ensure => present,
      cib    => 'l3',
      first  => "clone_p_${::neutron::params::ovs_agent_service}",
      second => "p_${::neutron::params::l3_agent_service}",
      score  => 'INFINITY',
    } -> Service['neutron-l3']

    cs_colocation { 'l3-with-metadata':
      ensure     => present,
      cib        => 'l3',
      primitives => [
          "p_${::neutron::params::l3_agent_service}",
          "clone_p_neutron-metadata-agent"
      ],
      score      => 'INFINITY',
    } ->
    cs_order { 'l3-after-metadata':
      ensure => present,
      cib    => "l3",
      first  => "clone_p_neutron-metadata-agent",
      second => "p_${::neutron::params::l3_agent_service}",
      score  => 'INFINITY',
    } -> Service['neutron-l3']

    # start DHCP and L3 agents on different controllers if it's possible
    cs_colocation { 'dhcp-without-l3':
      ensure     => present,
      cib        => 'l3',
      score      => '-100',
      primitives => [
        "p_${::neutron::params::dhcp_agent_service}",
        "p_${::neutron::params::l3_agent_service}"
      ],
    }

    # Ensure service is stopped  and disabled by upstart/init/etc.
    Anchor['neutron-l3'] ->
      Service['neutron-l3-init_stopped'] ->
        Cs_resource["p_${::neutron::params::l3_agent_service}"] ->
          Service['neutron-l3'] ->
            Anchor['neutron-l3-done']

    service { 'neutron-l3-init_stopped':
      name       => "${::neutron::params::l3_agent_service}",
      enable     => false,
      ensure     => stopped,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::neutron::params::service_provider,
    }

    service { 'neutron-l3':
      name       => "p_${::neutron::params::l3_agent_service}",
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => false,
      provider   => "pacemaker",
    }

  } else {
    Neutron_config <| |> ~> Service['neutron-l3']
    Neutron_l3_agent_config <| |> ~> Service['neutron-l3']
    File<| title=='neutron-logging.conf' |> ->
    service { 'neutron-l3':
      name       => $::neutron::params::l3_agent_service,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::neutron::params::service_provider,
    }
  }

  anchor {'neutron-l3-cellar': }
  Anchor['neutron-l3-cellar'] -> Anchor['neutron-l3-done']
  anchor {'neutron-l3-done': }
  Anchor['neutron-l3'] -> Anchor['neutron-l3-done']

}

# vim: set ts=2 sw=2 et :
