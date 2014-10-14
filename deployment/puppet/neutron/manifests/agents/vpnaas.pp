#
class neutron::agents::vpnaas (
  $neutron_config     = {},
  $verbose          = false,
  $debug            = false,
  $service_provider = 'generic',
  $primary_controller = false
) {
  include 'neutron::params'

  Anchor<| title=='neutron-l3-done' |> ->
  anchor {'neutron-vpnaas': }
  Service<| title=='neutron-server' |> -> Anchor['neutron-vpnaas']

  if $::neutron::params::vpnaas_agent_package {
    $vpnaas_agent_package = 'neutron-vpnaas'

    package { 'neutron-vpnaas':
      name   => $::neutron::params::vpnaas_agent_package,
      ensure => present,
    }
    # do not move it to outside this IF
    Package['neutron-vpnaas'] -> Neutron_vpnaas_agent_config <| |>
  } else {
    $vpnaas_agent_package = $::neutron::params::package_name
  }
  if $::neutron::params::openswan_package {
    package { 'neutron-vpnaas-openswan':
      name   => $::neutron::params::openswan_package,
      ensure => present,
    }
  }

  Package<| title == 'neutron-vpnaas-openswan'|> ~> Service<| title == 'openswan-ipsec'|>
  service { 'openswan-ipsec':
    name       => $::neutron::params::openswan_service,
    enable     => true,
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    provider   => $::neutron::params::service_provider,
  }

  include 'neutron::waist_setup'

  Neutron_l3_agent_config <| |> -> Neutron_vpnaas_agent_config <| |>
  Neutron_vpnaas_agent_config <| |> -> Service['neutron-vpnaas']

  neutron_vpnaas_agent_config {
    'DEFAULT/debug':          value => $debug;
    'DEFAULT/verbose':        value => $verbose;
    'DEFAULT/interface_driver': value => 'neutron.agent.linux.interface.OVSInterfaceDriver';
  }

  Anchor['neutron-vpnaas'] ->
    Service<| title=='openswan-ipsec' |>  ->
      Neutron_vpnaas_agent_config <| |> ->
          Service<| title=='neutron-vpnaas' |>  ->
              Anchor['neutron-vpnaas-done']

  Service<| title == 'neutron-server' |> -> Service['neutron-vpnaas']

  if $service_provider == 'pacemaker' {

    # OCF script for pacemaker
    # and his dependences
    file {'neutron-vpnaas-agent-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/neutron-agent-vpnaas',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => "puppet:///modules/neutron/ocf/neutron-agent-vpnaas",
    }

    Anchor['neutron-vpnaas'] -> File['neutron-vpnaas-agent-ocf']
    Neutron_vpnaas_agent_config <| |> -> File['neutron-vpnaas-agent-ocf']
    Package['pacemaker'] -> File['neutron-vpnaas-agent-ocf']
    File<| title == 'ocf-mirantis-path' |> -> File['neutron-vpnaas-agent-ocf']
    File<| title == 'q-agent-cleanup.py'|> -> File['neutron-vpnaas-agent-ocf']
    Package[$vpnaas_agent_package] -> File['neutron-vpnaas-agent-ocf']

    if $primary_controller {
      cs_resource { "p_${::neutron::params::vpnaas_agent_service}":
        ensure          => present,
        primitive_class => 'ocf',
        provided_by     => 'mirantis',
        primitive_type  => 'neutron-agent-vpnaas',
        parameters      => {
          'debug'       => $debug,
          'syslog'      => $::use_syslog,
          'os_auth_url' => $neutron_config['keystone']['auth_url'],
          'tenant'      => $neutron_config['keystone']['admin_tenant_name'],
          'username'    => $neutron_config['keystone']['admin_user'],
          'password'    => $neutron_config['keystone']['admin_password'],
        },
        metadata        => { 'resource-stickiness' => '1' },
        operations      => {
          'monitor'  => {
            'interval' => '20',
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
        },
      }

      Cs_resource["p_${::neutron::params::vpnaas_agent_service}"] ->
      cs_colocation { 'vpnaas-with-ovs':
        ensure     => present,
        primitives => ["p_${::neutron::params::vpnaas_agent_service}", "clone_p_${::neutron::params::ovs_agent_service}"],
        score      => 'INFINITY',
      } ->
      cs_order { 'vpnaas-after-ovs':
        ensure => present,
        first  => "clone_p_${::neutron::params::ovs_agent_service}",
        second => "p_${::neutron::params::vpnaas_agent_service}",
        score  => 'INFINITY',
      } -> Service['neutron-vpnaas']

      Cs_resource["p_${::neutron::params::vpnaas_agent_service}"] ->
      cs_colocation { 'vpnaas-with-metadata':
        ensure     => present,
        primitives => [
            "p_${::neutron::params::vpnaas_agent_service}",
            "clone_p_neutron-metadata-agent"
        ],
        score      => 'INFINITY',
      } ->
      cs_order { 'vpnaas-after-metadata':
        ensure => present,
        first  => "clone_p_neutron-metadata-agent",
        second => "p_${::neutron::params::vpnaas_agent_service}",
        score  => 'INFINITY',
      } -> Service['neutron-vpnaas']

      # start DHCP and L3 agents on different controllers if it's possible
      Cs_resource["p_${::neutron::params::vpnaas_agent_service}"] ->
      cs_colocation { 'dhcp-without-vpnaas':
        ensure     => present,
        score      => '-100',
        primitives => [
          "p_${::neutron::params::dhcp_agent_service}",
          "p_${::neutron::params::vpnaas_agent_service}"
        ],
      }

      Service['neutron-vpnaas-init_stopped'] ->
        Cs_resource["p_${::neutron::params::vpnaas_agent_service}"] ->
           Service['neutron-vpnaas']

      File['neutron-vpnaas-agent-ocf'] -> Cs_resource["p_${::neutron::params::vpnaas_agent_service}"]
    } else {

      File['neutron-vpnaas-agent-ocf'] -> Service['neutron-vpnaas']
    }

    Anchor<| title == 'neutron-ovs-agent-done' |> -> Anchor<| title=='neutron-vpnaas' |>
    Anchor<| title == 'neutron-metadata-agent-done' |> -> Anchor<| title=='neutron-vpnaas' |>
    Anchor<| title == 'neutron-dhcp-agent-done' |> -> Anchor<| title=='neutron-vpnaas' |>


    if !defined(Package['lsof']) {
      package { 'lsof': }
    }
    Package['lsof'] -> File['neutron-vpnaas-agent-ocf']

    # Ensure service is stopped  and disabled by upstart/init/etc.
    Anchor['neutron-vpnaas'] ->
      Service['neutron-vpnaas-init_stopped'] ->
        Service['neutron-vpnaas'] ->
          Anchor['neutron-vpnaas-done']

    service { 'neutron-vpnaas-init_stopped':
      name       => "${::neutron::params::vpnaas_agent_service}",
      enable     => false,
      ensure     => stopped,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::neutron::params::service_provider,
    }

    service { 'neutron-vpnaas':
      name       => "p_${::neutron::params::vpnaas_agent_service}",
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => "pacemaker",
    }

  } else {
    # No pacemaker use
    Neutron_config <| |> ~> Service['neutron-vpnaas']
    Neutron_vpnaas_agent_config <| |> ~> Service['neutron-vpnaas']
    service { 'neutron-vpnaas':
      name       => $::neutron::params::vpnaas_agent_service,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::neutron::params::service_provider,
    }
  }

  anchor {'neutron-vpnaas-cellar': }
  Anchor['neutron-vpnaas-cellar'] -> Anchor['neutron-vpnaas-done']
  anchor {'neutron-vpnaas-done': }
  Anchor['neutron-vpnaas'] -> Anchor['neutron-vpnaas-done']
  Package<| title == 'neutron-vpnaas'|> ~> Service<| title == 'neutron-vpnaas'|>
  if !defined(Service['neutron-vpnaas']) {
    notify{ "Module ${module_name} cannot notify service neutron-vpnaas on package update": }
  }

}
