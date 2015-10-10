# Not a doc string

class cluster::neutron::dhcp (
  $primary          = false,
  $ha_agents        = ['ovs', 'metadata', 'dhcp', 'l3'],
  $plugin_config    = '/etc/neutron/dhcp_agent.ini',
  $agents_per_net   = 2,      # Value, recommended by Neutron team.

) {

  require cluster::neutron

  Neutron_config<| name == 'DEFAULT/dhcp_agents_per_network' |> {
    value => $agents_per_net
  }
  $csr_metadata = undef
  $csr_complex_type    = 'clone'
  $csr_ms_metadata     = { 'interleave' => 'true' }

  $dhcp_agent_package = $::neutron::params::dhcp_agent_package ? {
    false   => $::neutron::params::package_name,
    default => $::neutron::params::dhcp_agent_package
  }

  #TODO (bogdando) move to extras ha wrappers
  cluster::corosync::cs_service {'dhcp':
    ocf_script      => 'neutron-dhcp-agent',
    csr_parameters  => {
      'plugin_config'                  => $plugin_config,
      'remove_artifacts_on_stop_start' => true,
    },
    csr_metadata        => $csr_metadata,
    csr_complex_type    => $csr_complex_type,
    csr_ms_metadata     => $csr_ms_metadata,
    csr_mon_intr    => '20',
    csr_mon_timeout => '30',
    csr_timeout     => '60',
    service_name    => $::neutron::params::dhcp_agent_service,
    package_name    => $dhcp_agent_package,
    service_title   => 'neutron-dhcp-service',
    primary         => $primary,
    hasrestart      => false,
  }

}
