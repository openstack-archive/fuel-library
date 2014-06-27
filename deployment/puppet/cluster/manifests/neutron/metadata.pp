# not a doc string

class cluster::neutron::metadata (
  ) {

  require cluster::neutron

  cluster::corosync::cs_service {'neutron-metadata-agent':
    ocf_script          => 'neutron-agent-metadata',
    csr_multistate_hash => { 'type' => 'clone' },
    csr_ms_metadata     => { 'interleave' => 'true' },
    csr_mon_intr        => '60',
    csr_mon_timeout     => '10',
    csr_timeout         => '30',
    service_name        => "p_${::neutron::params::metadata_agent_service}",
  }

  Neutron::Agents::Metadata {
    enabled         => false,
    manage_service  => false,
    before          => Cluster::Corosync::Cs_service['neutron-metadata-agent']
  }

}
