#
class quantum::agents::dhcp (
  $package_ensure   = 'present',
  $enabled          = true,
  $verbose          = 'False',
  $debug            = 'False',
  $state_path       = '/var/lib/quantum',
  $resync_interval  = 30,
  $interface_driver = 'quantum.agent.linux.interface.OVSInterfaceDriver',
  $dhcp_driver      = 'quantum.agent.linux.dhcp.Dnsmasq',
  $use_namespaces   = $::quantum_use_namespaces,
  $root_helper      = 'sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf',
  $service_provider = 'generic',
  $auth_url         = 'http://localhost:5000/v2.0',
  $auth_port        = '5000',
  $auth_tenant      = 'service',
  $auth_user        = 'quantum',
  $auth_password    = 'password') {
  include 'quantum::params'

  if $::quantum::params::dhcp_agent_package {
    Package['quantum'] -> Package['quantum-dhcp-agent']

    $dhcp_agent_package = 'quantum-dhcp-agent'

    package { 'quantum-dhcp-agent':
      name   => $::quantum::params::dhcp_agent_package,
      ensure => $package_ensure,
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
    'DEFAULT/debug':            value => $debug;
    'DEFAULT/state_path':       value => $state_path;
    'DEFAULT/resync_interval':  value => $resync_interval;
    'DEFAULT/interface_driver': value => $interface_driver;
    'DEFAULT/dhcp_driver':      value => $dhcp_driver;
    'DEFAULT/use_namespaces':   value => $use_namespaces;
    'DEFAULT/root_helper':      value => $root_helper;
    'DEFAULT/verbose':          value => $verbose;
  }

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  Service <| title == 'quantum-server' |> -> Service['quantum-dhcp-service']

  if $service_provider == 'pacemaker' {
    Service <| title == 'quantum-server' |> -> Cs_shadow['dhcp']
    Quantum_dhcp_agent_config <| |> -> Cs_shadow['dhcp']

    # OCF script for pacemaker
    # and his dependences
    file {'quantum-dhcp-agent-ocf':
      path=>'/usr/lib/ocf/resource.d/mirantis/quantum-agent-dhcp', 
      mode => 744,
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
        'os_auth_url' => $auth_url,
        'tenant'      => $auth_tenant,
        'username'    => $auth_user,
        'password'    => $auth_password,
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

    service { 'quantum-dhcp-service':
      name       => "p_${::quantum::params::dhcp_agent_service}",
      enable     => $enabled,
      ensure     => $ensure,
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
      enable     => $enabled,
      ensure     => $ensure,
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
