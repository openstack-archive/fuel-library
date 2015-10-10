# not a doc string

class cluster::neutron::metadata (
  $primary = false,
  ) {

  require cluster::neutron

  $metadata_agent_package = $::neutron::params::metadata_agent_package ? {
    false   => $::neutron::params::package_name,
    default => $::neutron::params::metadata_agent_package,
  }

  #TODO (bogdando) move to extras ha wrappers
  cluster::corosync::cs_service {'neutron-metadata-agent':
    ocf_script          => 'neutron-metadata-agent',
    csr_complex_type    => 'clone',
    csr_ms_metadata     => { 'interleave' => 'true' },
    csr_mon_intr        => '60',
    csr_mon_timeout     => '30',
    csr_timeout         => '30',
    service_name        => $::neutron::params::metadata_agent_service,
    package_name        => $metadata_agent_package,
    service_title       => 'neutron-metadata',
    primary             => $primary,
  }
}
