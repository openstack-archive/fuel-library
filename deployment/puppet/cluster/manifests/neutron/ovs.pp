# not a doc string

class cluster::neutron::ovs (
  $primary        = false,
  $plugin_config  = '/etc/neutron/plugins/ml2/openvswitch_agent.ini',
  ) {

  require cluster::neutron

  $ovs_agent_package = $::neutron::params::ovs_agent_package ? {
    false   => $::neutron::params::package_name,
    default => $::neutron::params::ovs_agent_package,
  }

  cluster::corosync::cs_service {'ovs':
    ocf_script       => 'neutron-ovs-agent',
    csr_complex_type => 'clone',
    csr_ms_metadata  => { 'interleave' => 'true' },
    csr_parameters   => { 'plugin_config' => $plugin_config },
    csr_mon_intr     => '20',
    csr_mon_timeout  => '30',
    csr_timeout      => '80',
    service_name     => $::neutron::params::ovs_agent_service,
    service_title    => 'neutron-ovs-agent-service',
    package_name     => $ovs_agent_package,
    primary          => $primary,
    hasrestart       => false,
  }
}
