# not a doc string

class cluster::neutron::ovs (
  $primary = false,
  $plugin_config  = '/etc/neutron/plugin.ini',
  ) {

  require cluster::neutron

  cluster::corosync::cs_service {'ovs':
    ocf_script          => 'neutron-agent-ovs',
    csr_multistate_hash => { 'type' => 'clone' },
    csr_ms_metadata     => { 'interleave' => 'true' },
    csr_parameters  => { 'plugin_config' => $plugin_config },

    csr_mon_intr        => '20',
    csr_mon_timeout     => '10',
    csr_timeout         => '80',
    service_name        => "${::neutron::params::ovs_agent_service}",
    primary             => $primary,
    hasrestart          => false,
  }

  if defined(Class['neutron::agents::ovs']) {
    #Legacy ovs is depracated, it should be removed after Juno
    Neutron::Agents::Ovs {
      enabled         => false,
      manage_service  => false,
      before          => Cluster::Corosync::Cs_service['ovs']
    }
  } else {
    Neutron::Agents::Ml2::Ovs {
      enabled         => false,
      manage_service  => false,
      before          => Cluster::Corosync::Cs_service['ovs']
    }
  }
}
