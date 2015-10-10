# not a doc string

define cluster::neutron::l3 (
  $plugin_config   = '/etc/neutron/l3_agent.ini',
  $primary         = false,
  $ha_agents       = ['ovs', 'metadata', 'dhcp', 'l3'],

) {

  require cluster::neutron

  $csr_metadata = undef
  $csr_complex_type    = 'clone'
  $csr_ms_metadata     = { 'interleave' => 'true' }

  $l3_agent_package = $::neutron::params::l3_agent_package ? {
    false   => $::neutron::params::package_name,
    default => $::neutron::params::l3_agent_package,
  }

  #TODO (bogdando) move to extras ha wrappers
  cluster::corosync::cs_service {'l3':
    ocf_script      => 'neutron-l3-agent',
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
    service_name    => $::neutron::params::l3_agent_service,
    package_name    => $l3_agent_package,
    service_title   => 'neutron-l3',
    primary         => $primary,
    hasrestart      => false,
  }
}
