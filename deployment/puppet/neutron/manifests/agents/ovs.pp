class neutron::agents::ovs (
  $neutron_config     = {},
  $service_provider   = 'generic'
) {

  include 'neutron::params'
  include 'neutron::waist_setup'

  $res_name = "p_${::neutron::params::ovs_agent_service}"

  Anchor<| title=='neutron-plugin-ovs-done' |> -> Anchor['neutron-ovs-agent']
  Anchor<| title=='neutron-server-done' |> -> Anchor['neutron-ovs-agent']
  Service<| title=='neutron-server' |> -> Anchor['neutron-ovs-agent']
  anchor {'neutron-ovs-agent': }

  Neutron_config <| |> -> Neutron_plugin_ovs <| |>

  # Package install
  if $::neutron::params::ovs_agent_package {
    $ovs_agent_package = 'neutron-plugin-ovs-agent'
    Package['neutron'] -> Package["$ovs_agent_package"]
    package {"${ovs_agent_package}":
      name   => $::neutron::params::ovs_agent_package,
    }
  } else {
    $ovs_agent_package = $::neutron::params::ovs_server_package
  }

  if $::operatingsystem == 'Ubuntu' {
    file { "/etc/init/neutron-plugin-openvswitch-agent.override":
      replace => "no",
      ensure  => "present",
      content => "manual",
      mode    => '0644',
    } -> Package<| title=="$ovs_agent_package" |>
    if $service_provider != 'pacemaker' {
      Package<| title=="$ovs_agent_package" |> ->
      exec { 'rm-neutron-plugin-override':
        path      => '/sbin:/bin:/usr/bin:/usr/sbin',
        command   => "rm -f /etc/init/neutron-plugin-openvswitch-agent.override",
      }
    }
  }

  if !defined(Anchor['neutron-server-done']) {
    # if defined -- this depends already defined
    Package[$ovs_agent_package] -> Neutron_plugin_ovs <| |>
  }

  ###

  neutron::agents::utils::bridges { $neutron_config['L2']['integration_bridge']: }
  if $neutron_config['L2']['enable_tunneling'] {
    neutron::agents::utils::bridges { $neutron_config['L2']['tunnel_bridge']: }
    neutron_plugin_ovs { 'ovs/local_ip':  value => $neutron_config['L2']['local_ip'] }
  } else {
    neutron::agents::utils::bridges { $neutron_config['L2']['phys_bridges']: }
  }

  if $service_provider == 'pacemaker' {
    Neutron_config <| |> -> Cs_shadow['ovs']
    Neutron_plugin_ovs <| |> -> Cs_shadow['ovs']  # OVS plugin and agent should be configured before resource created
    Neutron::Agents::Utils::Bridges <| |> -> Cs_shadow['ovs']  # All bridges should be created before ovs-agent resource create

    cs_shadow { 'ovs': cib => 'ovs' }
    cs_commit { 'ovs': cib => 'ovs' }
    Anchor['neutron-ovs-agent'] -> Cs_shadow['ovs']

    # OCF script for pacemaker
    # and his dependences
    file {'neutron-ovs-agent-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/neutron-agent-ovs',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => "puppet:///modules/neutron/ocf/neutron-agent-ovs",
    }
    File['neutron-ovs-agent-ocf'] -> Cs_resource[$res_name]
    File<| title == 'ocf-mirantis-path' |> -> File['neutron-ovs-agent-ocf']
    Anchor['neutron-ovs-agent'] -> File['neutron-ovs-agent-ocf']
    Package["$ovs_agent_package"] -> Neutron_plugin_ovs <| |>
    Neutron_plugin_ovs <| |> -> File['neutron-ovs-agent-ocf']

    cs_resource { $res_name:
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
          'timeout'  => '10'
        },
        'start'    => {
          'timeout' => '80'
        },
        'stop'     => {
          'timeout' => '80'
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
            Cs_resource[$res_name] ->
             Cs_commit['ovs'] ->
              Service['neutron-ovs-agent']

    service { 'neutron-ovs-agent':
      name       => $res_name,
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
    Neutron::Agents::Utils::Bridges<||> -> Service['neutron-ovs-agent']  # All bridges should be created before ovs-agent service
  }
  Neutron_config<||> -> Service['neutron-ovs-agent']
  Neutron_plugin_ovs<||> -> Service['neutron-ovs-agent']

  Class[neutron::waistline] -> Service['neutron-ovs-agent']

  Anchor['neutron-ovs-agent'] ->
    Service['neutron-ovs-agent'] ->
      Anchor['neutron-ovs-agent-done']

  anchor{'neutron-ovs-agent-done': }

  Anchor['neutron-ovs-agent-done'] -> Anchor<| title=='neutron-l3' |>
  Anchor['neutron-ovs-agent-done'] -> Anchor<| title=='neutron-dhcp-agent' |>
  Anchor['neutron-ovs-agent-done'] -> Anchor<| title=='neutron-metadata-agent' |>

  Package<| title == $ovs_agent_package |> ~> Service<| title == 'neutron-ovs-agent'|>
  if !defined(Service['neutron-ovs-agent']) {
    notify{ "Module ${module_name} cannot notify service neutron-ovs-agent on package update": }
  }

}
