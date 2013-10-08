#
class quantum::agents::dhcp (
  $quantum_config     = {},
  $verbose          = 'False',
  $debug            = 'False',
  $interface_driver = 'quantum.agent.linux.interface.OVSInterfaceDriver',
  $dhcp_driver      = 'quantum.agent.linux.dhcp.Dnsmasq',
  $dhcp_agent_manager='quantum.agent.dhcp_agent.DhcpAgentWithStateReport',
  $state_path       = '/var/lib/quantum',
  $service_provider = 'generic',
) {
  include 'quantum::params'

  if $::operatingsystem == 'Ubuntu' {
    if $service_provider == 'pacemaker' {
       file { "/etc/init/quantum-dhcp-agent.override":
         replace => "no",
         ensure  => "present",
         content => "manual",
         mode    => 644,
         before  => Package['quantum-dhcp-agent'],
       }
    }
  }

  if $::quantum::params::dhcp_agent_package {
    Package['quantum'] -> Package['quantum-dhcp-agent']

    $dhcp_agent_package = 'quantum-dhcp-agent'

    package { 'quantum-dhcp-agent':
      name   => $::quantum::params::dhcp_agent_package
    }
  } else {
    $dhcp_agent_package = $::quantum::params::package_name
  }

  include 'quantum::waist_setup'

  anchor {'quantum-dhcp-agent': }

  #Anchor['quantum-metadata-agent-done'] -> Anchor['quantum-dhcp-agent']
  Service<| title=='quantum-server' |> -> Anchor['quantum-dhcp-agent']

  case $dhcp_driver {
    /\.Dnsmasq/ : {
      package { $::quantum::params::dnsmasq_packages: ensure => present, }
      Package[$::quantum::params::dnsmasq_packages] -> Package[$dhcp_agent_package]
      $dhcp_server_packages = $::quantum::params::dnsmasq_packages
    }
    default     : {
      fail("${dhcp_driver} is not supported as of now")
    }
  }

  Package[$dhcp_agent_package] -> Quantum_dhcp_agent_config <| |>
  Package[$dhcp_agent_package] -> Quantum_config <| |>

  quantum_dhcp_agent_config {
    'DEFAULT/debug':             value => $debug;
    'DEFAULT/verbose':           value => $verbose;
    'DEFAULT/state_path':        value => $state_path;
    'DEFAULT/interface_driver':  value => $interface_driver;
    'DEFAULT/dhcp_driver':       value => $dhcp_driver;
    'DEFAULT/dhcp_agent_manager':value => $dhcp_agent_manager;
    'DEFAULT/auth_url':          value => $quantum_config['keystone']['auth_url'];
    'DEFAULT/admin_user':        value => $quantum_config['keystone']['admin_user'];
    'DEFAULT/admin_password':    value => $quantum_config['keystone']['admin_password'];
    'DEFAULT/admin_tenant_name': value => $quantum_config['keystone']['admin_tenant_name'];
    'DEFAULT/resync_interval':   value => $quantum_config['L3']['resync_interval'];
    'DEFAULT/use_namespaces':    value => $quantum_config['L3']['use_namespaces'];
    'DEFAULT/root_helper':       value => $quantum_config['root_helper'];
    'DEFAULT/signing_dir':       value => $quantum_config['keystone']['signing_dir'];
    'DEFAULT/enable_isolated_metadata': value => $quantum_config['L3']['dhcp_agent']['enable_isolated_metadata'];
    'DEFAULT/enable_metadata_network':  value => $quantum_config['L3']['dhcp_agent']['enable_metadata_network'];
  }

  Service <| title == 'quantum-server' |> -> Service['quantum-dhcp-service']

  if $service_provider == 'pacemaker' {
    Service <| title == 'quantum-server' |> -> Cs_shadow['dhcp']
    Quantum_dhcp_agent_config <| |> -> Cs_shadow['dhcp']

    # OCF script for pacemaker
    # and his dependences
    file {'quantum-dhcp-agent-ocf':
      path=>'/usr/lib/ocf/resource.d/mirantis/quantum-agent-dhcp',
      mode => 755,
      owner => root,
      group => root,
      source => "puppet:///modules/quantum/ocf/quantum-agent-dhcp",
    }
    Package['pacemaker'] -> File['quantum-dhcp-agent-ocf']
    File['quantum-dhcp-agent-ocf'] -> Cs_resource["p_${::quantum::params::dhcp_agent_service}"]
    File['q-agent-cleanup.py'] -> Cs_resource["p_${::quantum::params::dhcp_agent_service}"]
    File<| title=='quantum-logging.conf' |> ->
    cs_resource { "p_${::quantum::params::dhcp_agent_service}":
      ensure          => present,
      cib             => 'dhcp',
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'quantum-agent-dhcp',
      #require => File['quantum-agent-dhcp'],
      parameters      => {
        'os_auth_url' => $quantum_config['keystone']['auth_url'],
        'tenant'      => $quantum_config['keystone']['admin_tenant_name'],
        'username'    => $quantum_config['keystone']['admin_user'],
        'password'    => $quantum_config['keystone']['admin_password'],
      }
      ,
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
      }
      ,
    }

    Cs_commit <| title == 'ovs' |> -> Cs_shadow <| title == 'dhcp' |>
    Cs_commit <| title == 'quantum-metadata-agent' |> -> Cs_shadow <| title == 'dhcp' |>

    ::corosync::cleanup { "p_${::quantum::params::dhcp_agent_service}": }
    Cs_commit['dhcp'] -> ::Corosync::Cleanup["p_${::quantum::params::dhcp_agent_service}"]
    Cs_commit['dhcp'] ~> ::Corosync::Cleanup["p_${::quantum::params::dhcp_agent_service}"]
    ::Corosync::Cleanup["p_${::quantum::params::dhcp_agent_service}"] -> Service['quantum-dhcp-service']
    Cs_resource["p_${::quantum::params::dhcp_agent_service}"] -> Cs_colocation['dhcp-with-ovs']
    Cs_resource["p_${::quantum::params::dhcp_agent_service}"] -> Cs_order['dhcp-after-ovs']
    Cs_resource["p_${::quantum::params::dhcp_agent_service}"] -> Cs_colocation['dhcp-with-metadata']
    Cs_resource["p_${::quantum::params::dhcp_agent_service}"] -> Cs_order['dhcp-after-metadata']

    cs_shadow { 'dhcp': cib => 'dhcp' }
    cs_commit { 'dhcp': cib => 'dhcp' }

    cs_colocation { 'dhcp-with-ovs':
      ensure     => present,
      cib        => 'dhcp',
      primitives => [
        "p_${::quantum::params::dhcp_agent_service}",
        "clone_p_${::quantum::params::ovs_agent_service}"
      ],
      score      => 'INFINITY',
    } ->
    cs_order { 'dhcp-after-ovs':
      ensure => present,
      cib    => 'dhcp',
      first  => "clone_p_${::quantum::params::ovs_agent_service}",
      second => "p_${::quantum::params::dhcp_agent_service}",
      score  => 'INFINITY',
    } -> Service['quantum-dhcp-service']

    cs_colocation { 'dhcp-with-metadata':
      ensure     => present,
      cib        => 'dhcp',
      primitives => [
        "p_${::quantum::params::dhcp_agent_service}",
        "clone_p_quantum-metadata-agent"
      ],
      score      => 'INFINITY',
    } ->
    cs_order { 'dhcp-after-metadata':
      ensure => present,
      cib    => 'dhcp',
      first  => "clone_p_quantum-metadata-agent",
      second => "p_${::quantum::params::dhcp_agent_service}",
      score  => 'INFINITY',
    } -> Service['quantum-dhcp-service']

    Service['quantum-dhcp-service_stopped'] -> Cs_resource["p_${::quantum::params::dhcp_agent_service}"]

    service { 'quantum-dhcp-service_stopped':
      name       => "${::quantum::params::dhcp_agent_service}",
      enable     => false,
      ensure     => stopped,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::quantum::params::service_provider,
      require    => [Package[$dhcp_agent_package], Class['quantum']],
    }

    Quantum::Network::Provider_router<||> -> Service<| title=='quantum-dhcp-service' |>
    service { 'quantum-dhcp-service':
      name       => "p_${::quantum::params::dhcp_agent_service}",
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => false,
      provider   => $service_provider,
      require    => [Package[$dhcp_agent_package], Class['quantum'], Service['quantum-ovs-agent']],
    }

  } else {
    Quantum_config <| |> ~> Service['quantum-dhcp-service']
    Quantum_dhcp_agent_config <| |> ~> Service['quantum-dhcp-service']
    File<| title=='quantum-logging.conf' |> ->
    service { 'quantum-dhcp-service':
      name       => $::quantum::params::dhcp_agent_service,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::quantum::params::service_provider,
      require    => [Package[$dhcp_agent_package], Class['quantum'], Service['quantum-ovs-agent']],
    }
  }
  Class[quantum::waistline] -> Service[quantum-dhcp-service]

  Anchor['quantum-dhcp-agent'] ->
    Quantum_dhcp_agent_config <| |> ->
      Cs_resource<| title=="p_${::quantum::params::dhcp_agent_service}" |> ->
        Service['quantum-dhcp-service'] ->
          Anchor['quantum-dhcp-agent-done']

  anchor {'quantum-dhcp-agent-done': }

}

# vim: set ts=2 sw=2 et :
