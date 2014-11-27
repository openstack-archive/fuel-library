# Not a doc string

class cluster::neutron::dhcp (
  $primary    = false,
  $ha_agents  = ['ovs', 'metadata', 'dhcp', 'l3'],
  $amqp_server_port  = 5673,
  $multiple_agents   = false,  # will be enabled as default at 6.1
  $agents_per_net    = 3,      # Value, recommended by Neutron team.

  #keystone settings
  $admin_password    = 'asdf123',
  $admin_tenant_name = 'services',
  $admin_username    = 'neutron',
  $auth_url          = 'http://localhost:35357/v2.0'
) {

  require cluster::neutron

  if $multiple_agents {
    Neutron_config<| name == 'DEFAULT/dhcp_agents_per_network' |> {
      value => $agents_per_net
    }
    $csr_metadata = undef
    $csr_complex_type    = 'clone'
    $csr_ms_metadata     = { 'interleave' => 'true' }
  } else {
    $csr_metadata        = { 'resource-stickiness' => '1' }
    $csr_complex_type    = undef
    $csr_ms_metadata     = undef
  }

  $dhcp_agent_package = $::neutron::params::dhcp_agent_package ? {
    false   => $::neutron::params::package_name,
    default => $::neutron::params::dhcp_agent_package
  }

  #TODO (bogdando) move to extras ha wrappers
  cluster::corosync::cs_service {'dhcp':
    ocf_script      => 'neutron-agent-dhcp',
    csr_parameters  => {
      'os_auth_url'      => $auth_url,
      'tenant'           => $admin_tenant_name,
      'username'         => $admin_user,
      'password'         => $admin_password,
      'multiple_agents'  => $multiple_agents,
      'amqp_server_port' => $amqp_server_port
    },
    csr_metadata        => $csr_metadata,
    csr_complex_type    => $csr_complex_type,
    csr_ms_metadata     => $csr_ms_metadata,
    csr_mon_intr    => '20',
    csr_mon_timeout => '10',
    csr_timeout     => '60',
    service_name    => $::neutron::params::dhcp_agent_service,
    package_name    => $dhcp_agent_package,
    service_title   => 'neutron-dhcp-service',
    primary         => $primary,
    hasrestart      => false,
  }

  if ( 'ovs' in $ha_agents or 'ml2-ovs' in $ha_agents ) {
    cluster::corosync::cs_with_service {'dhcp-and-ovs':
      first   => "clone_p_${::neutron::params::ovs_agent_service}",
      second  => $multiple_agents ? {
                    false   => "p_${::neutron::params::dhcp_agent_service}",
                    default => "clone_p_${::neutron::params::dhcp_agent_service}"
                 },
      require => Cluster::Corosync::Cs_service['ovs','dhcp']
    }
  }

}
