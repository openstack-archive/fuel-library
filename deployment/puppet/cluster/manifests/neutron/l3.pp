# not a doc string

define cluster::neutron::l3 (
  $debug          = false,
  $verbose        = false,
  $syslog         = $::use_syslog,
  $plugin_config  = '/etc/neutron/l3_agent.ini',
  $primary        = false,
  $ha_agents      = ['ovs', 'metadata', 'dhcp', 'l3'],

  #keystone settings
  $admin_password    = 'asdf123',
  $admin_tenant_name = 'services',
  $admin_username    = 'neutron',
  $auth_url          = 'http://localhost:35357/v2.0'
) {

  require cluster::neutron

  cluster::corosync::cs_service {'l3':
    ocf_script      => 'neutron-agent-l3',
    csr_parameters  => {
      'debug'         => $debug,
      'syslog'        => $syslog,
      'plugin_config' => $plugin_config,
      'os_auth_url'   => $auth_url,
      'tenant'        => $admin_tenant_name,
      'username'      => $admin_user,
      'password'      => $admin_password,
    },
    csr_metadata    => { 'resource-stickiness' => '1' },
    csr_mon_intr    => '20',
    csr_mon_timeout => '10',
    csr_timeout     => '60',
    service_name    => $::neutron::params::l3_agent_service,
    package         => $::neutron::params::l3_agent_package,
    primary         => $primary,
    hasrestart      => false,
  }

  if ( 'ovs' in $ha_agents or 'ml2-ovs' in $ha_agents ) {
    cluster::corosync::cs_with_service {'l3-and-ovs':
      first   => "clone_p_${::neutron::params::ovs_agent_service}",
      second  => "p_${::neutron::params::l3_agent_service}",
      require => Cluster::Corosync::Cs_service['ovs','l3'],
    }
  }

  if 'metadata' in $ha_agents {
    Cluster::Corosync::Cs_service <| title == 'neutron-metadata-agent' |> ->
    Cluster::Corosync::Cs_service['l3'] ->
    cluster::corosync::cs_with_service {'l3-and-metadata':
      first   => "clone_p_${::neutron::params::metadata_agent_service}",
      second  => "p_${::neutron::params::l3_agent_service}",
    }
  }

  if 'dhcp' in $ha_agents {
    cs_colocation { 'l3-keepaway-dhcp':
      ensure     => present,
      score      => '-100',
      primitives => [
        "p_${::neutron::params::dhcp_agent_service}",
        "p_${::neutron::params::l3_agent_service}"
      ],
      require => Cluster::Corosync::Cs_service['dhcp','l3'],
    }
  }
}