#
class neutron::agents::dhcp (
  $neutron_config     = {},
  $verbose          = false,
  $debug            = false,
  $interface_driver = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $dhcp_driver      = 'neutron.agent.linux.dhcp.Dnsmasq',
  $dhcp_agent_manager='neutron.agent.dhcp_agent.DhcpAgentWithStateReport',
  $state_path       = '/var/lib/neutron',
  $service_provider = 'generic',
) {
  include 'neutron::params'

  if $::neutron::params::dhcp_agent_package {
    Package['neutron'] -> Package['neutron-dhcp-agent']

    $dhcp_agent_package = 'neutron-dhcp-agent'

    package { 'neutron-dhcp-agent':
      name   => $::neutron::params::dhcp_agent_package
    }
  } else {
    $dhcp_agent_package = $::neutron::params::package_name
  }
  if $::operatingsystem == 'Ubuntu' {
    file { '/etc/init/neutron-dhcp-agent.override':
     replace => 'no',
     ensure  => 'present',
     content => 'manual',
     mode    => '0644',
    } -> Package<| title=="$dhcp_agent_package" |>
    if $service_provider != 'pacemaker' {
       Package<| title=="$dhcp_agent_package" |> ->
       exec { 'rm-neutron-dhcp-override':
         path => '/sbin:/bin:/usr/bin:/usr/sbin',
         command => "rm -f /etc/init/neutron-dhcp-agent.override",
       }
    }
  }


  include 'neutron::waist_setup'

  Anchor<| title=='neutron-server-done' |> ->
  anchor {'neutron-dhcp-agent': }

  #Anchor['neutron-metadata-agent-done'] -> Anchor['neutron-dhcp-agent']
  Service<| title=='neutron-server' |> -> Anchor['neutron-dhcp-agent']

  case $dhcp_driver {
    /\.Dnsmasq/ : {
      package { $::neutron::params::dnsmasq_packages: ensure => present, }
      Package[$::neutron::params::dnsmasq_packages] -> Package[$dhcp_agent_package]
      $dhcp_server_packages = $::neutron::params::dnsmasq_packages
    }
    default: {
      fail("${dhcp_driver} is not supported as of now")
    }
  }

  Package[$dhcp_agent_package] -> Neutron_dhcp_agent_config <| |>
  Package[$dhcp_agent_package] -> Neutron_config <| |>

  neutron_dhcp_agent_config {
    'DEFAULT/debug':             value => $debug;
    'DEFAULT/verbose':           value => $verbose;
    'DEFAULT/log_dir':          ensure => absent;
    'DEFAULT/log_file':         ensure => absent;
    'DEFAULT/log_config':       ensure => absent;
    #TODO(bogdando) fix syslog usage after Oslo logging patch synced in I
    'DEFAULT/use_syslog':       ensure => absent;
    'DEFAULT/use_stderr':       ensure => absent;
    'DEFAULT/state_path':        value => $state_path;
    'DEFAULT/interface_driver':  value => $interface_driver;
    'DEFAULT/dhcp_driver':       value => $dhcp_driver;
    'DEFAULT/dhcp_agent_manager':value => $dhcp_agent_manager;
    'DEFAULT/auth_url':          value => $neutron_config['keystone']['auth_url'];
    'DEFAULT/admin_user':        value => $neutron_config['keystone']['admin_user'];
    'DEFAULT/admin_password':    value => $neutron_config['keystone']['admin_password'];
    'DEFAULT/admin_tenant_name': value => $neutron_config['keystone']['admin_tenant_name'];
    'DEFAULT/resync_interval':   value => $neutron_config['L3']['resync_interval'];
    'DEFAULT/use_namespaces':    value => $neutron_config['L3']['use_namespaces'];
    'DEFAULT/dhcp_delete_namespaces':   value => 'False';  # Neutron can't properly clean network namespace before delete.
    'DEFAULT/root_helper':       value => $neutron_config['root_helper'];
    'DEFAULT/signing_dir':       value => $neutron_config['keystone']['signing_dir'];
    'DEFAULT/enable_isolated_metadata': value => $neutron_config['L3']['dhcp_agent']['enable_isolated_metadata'];
    'DEFAULT/enable_metadata_network':  value => $neutron_config['L3']['dhcp_agent']['enable_metadata_network'];
  }

  Service <| title == 'neutron-server' |> -> Service['neutron-dhcp-service']

  if $service_provider == 'pacemaker' {
    Service <| title == 'neutron-server' |> -> Cs_shadow['dhcp']
    Neutron_dhcp_agent_config <| |> -> Cs_shadow['dhcp']
    Anchor['neutron-dhcp-agent'] -> Cs_shadow['dhcp']

    # OCF script for pacemaker
    # and his dependences
    file {'neutron-dhcp-agent-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/neutron-agent-dhcp',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => "puppet:///modules/neutron/ocf/neutron-agent-dhcp",
    }

    Package['pacemaker'] -> File['neutron-dhcp-agent-ocf']
    File['neutron-dhcp-agent-ocf'] -> Cs_resource["p_${::neutron::params::dhcp_agent_service}"]
    File['q-agent-cleanup.py'] -> Cs_resource["p_${::neutron::params::dhcp_agent_service}"]
    File<| title == 'neutron-logging.conf' |> -> Cs_resource["p_${::neutron::params::dhcp_agent_service}"]
    File<| title == 'ocf-mirantis-path' |> -> File['neutron-dhcp-agent-ocf']
    Anchor['neutron-dhcp-agent'] -> File['neutron-dhcp-agent-ocf']
    Neutron_config <| |> -> File['neutron-dhcp-agent-ocf']
    Neutron_dhcp_agent_config <| |> -> File['neutron-dhcp-agent-ocf']
    Package[$dhcp_agent_package] -> File['neutron-dhcp-agent-ocf']

    cs_resource { "p_${::neutron::params::dhcp_agent_service}":
      ensure          => present,
      cib             => 'dhcp',
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'neutron-agent-dhcp',
      parameters      => {
        'os_auth_url' => $neutron_config['keystone']['auth_url'],
        'tenant'      => $neutron_config['keystone']['admin_tenant_name'],
        'username'    => $neutron_config['keystone']['admin_user'],
        'password'    => $neutron_config['keystone']['admin_password'],
      },
      metadata        => { 'resource-stickiness' => '1' },
      operations      => {
        'monitor'  => {
          'interval' => '30',
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
      }
      ,
    }

    Cs_commit <| title == 'ovs' |> -> Cs_shadow <| title == 'dhcp' |>
    Cs_commit <| title == 'neutron-metadata-agent' |> -> Cs_shadow <| title == 'dhcp' |>

    Cs_resource["p_${::neutron::params::dhcp_agent_service}"] -> Cs_colocation['dhcp-with-ovs']
    Cs_resource["p_${::neutron::params::dhcp_agent_service}"] -> Cs_order['dhcp-after-ovs']
    Cs_resource["p_${::neutron::params::dhcp_agent_service}"] -> Cs_colocation['dhcp-with-metadata']
    Cs_resource["p_${::neutron::params::dhcp_agent_service}"] -> Cs_order['dhcp-after-metadata']

    cs_shadow { 'dhcp': cib => 'dhcp' }
    cs_commit { 'dhcp': cib => 'dhcp' }

    Anchor <| title == 'neutron-ovs-agent-done' |> -> Anchor['neutron-dhcp-agent']
    cs_colocation { 'dhcp-with-ovs':
      ensure     => present,
      cib        => 'dhcp',
      primitives => [
        "p_${::neutron::params::dhcp_agent_service}",
        "clone_p_${::neutron::params::ovs_agent_service}"
      ],
      score      => 'INFINITY',
    } ->
    cs_order { 'dhcp-after-ovs':
      ensure => present,
      cib    => 'dhcp',
      first  => "clone_p_${::neutron::params::ovs_agent_service}",
      second => "p_${::neutron::params::dhcp_agent_service}",
      score  => 'INFINITY',
    } -> Service['neutron-dhcp-service']

    Anchor <| title == 'neutron-metadata-agent-done' |> -> Anchor['neutron-dhcp-agent']
    cs_colocation { 'dhcp-with-metadata':
      ensure     => present,
      cib        => 'dhcp',
      primitives => [
        "p_${::neutron::params::dhcp_agent_service}",
        "clone_p_neutron-metadata-agent"
      ],
      score      => 'INFINITY',
    } ->
    cs_order { 'dhcp-after-metadata':
      ensure => present,
      cib    => 'dhcp',
      first  => "clone_p_neutron-metadata-agent",
      second => "p_${::neutron::params::dhcp_agent_service}",
      score  => 'INFINITY',
    } -> Service['neutron-dhcp-service']

    Service['neutron-dhcp-service_stopped'] -> Cs_resource["p_${::neutron::params::dhcp_agent_service}"]

    if !defined(Package['lsof']) {
      package { 'lsof': } -> Cs_resource["p_${::neutron::params::dhcp_agent_service}"]
    }

    service { 'neutron-dhcp-service_stopped':
      name       => "${::neutron::params::dhcp_agent_service}",
      enable     => false,
      ensure     => stopped,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::neutron::params::service_provider,
      require    => [Package[$dhcp_agent_package], Class['neutron']],
    }

    Neutron::Network::Provider_router<||> -> Service<| title=='neutron-dhcp-service' |>
    service { 'neutron-dhcp-service':
      name       => "p_${::neutron::params::dhcp_agent_service}",
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => false,
      provider   => $service_provider,
      require    => [Package[$dhcp_agent_package], Class['neutron'], Service['neutron-ovs-agent']],
    }

  } else {
    Neutron_config <| |> ~> Service['neutron-dhcp-service']
    Neutron_dhcp_agent_config <| |> ~> Service['neutron-dhcp-service']
    File<| title=='neutron-logging.conf' |> ->
    service { 'neutron-dhcp-service':
      name       => $::neutron::params::dhcp_agent_service,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::neutron::params::service_provider,
      require    => [Package[$dhcp_agent_package], Class['neutron'], Service['neutron-ovs-agent']],
    }
  }
  Class[neutron::waistline] -> Service[neutron-dhcp-service]

  Anchor['neutron-dhcp-agent'] ->
    Cs_resource<| title=="p_${::neutron::params::dhcp_agent_service}" |> ->
      Cs_commit <| title== 'dhcp' |> ->
        Service['neutron-dhcp-service'] ->
          Anchor['neutron-dhcp-agent-done']

  anchor {'neutron-dhcp-agent-done': }
  Package<| title == 'neutron-dhcp-agent'|> ~> Service<| title == 'neutron-dhcp-service'|>
  if !defined(Service['neutron-dhcp-service']) {
    notify{ "Module ${module_name} cannot notify service neutron-dhcp-service on package update": }
  }
}

