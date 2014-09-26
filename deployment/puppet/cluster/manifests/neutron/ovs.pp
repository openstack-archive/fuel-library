# not a doc string

class cluster::neutron::ovs (
  $primary        = false,
  $plugin_config  = '/etc/neutron/plugin.ini',
  ) {

  require cluster::neutron

  cluster::corosync::cs_service {'ovs':
    ocf_script          => 'neutron-agent-ovs',
    csr_multistate_hash => { 'type' => 'clone' },
    csr_ms_metadata     => { 'interleave' => 'true' },
    csr_parameters      => { 'plugin_config' => $plugin_config },
    csr_mon_intr        => '20',
    csr_mon_timeout     => '10',
    csr_timeout         => '80',
    service_name        => $::neutron::params::ovs_agent_service,
    package             => $::neutron::params::ovs_agent_package,
    primary             => $primary,
    hasrestart          => false,
  }
}
