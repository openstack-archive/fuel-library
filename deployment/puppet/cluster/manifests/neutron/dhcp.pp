# Not a doc string

class cluster::neutron::dhcp (
  $ha_agents      = ['ovs', 'metadata', 'dhcp', 'l3'],

  #keystone settings
  $admin_password    = 'asdf123',
  $admin_tenant_name = 'services',
  $admin_username    = 'neutron',
  $auth_url          = 'http://localhost:35357/v2.0'
  ) {

  require cluster::neutron

  cluster::corosync::cs_service {'dhcp':
    ocf_script      => 'neutron-agent-dhcp',
    csr_parameters  => {
      'os_auth_url' => $auth_url,
      'tenant'      => $admin_tenant_name,
      'username'    => $admin_user,
      'password'    => $admin_password,
    },
    csr_metadata    => { 'resource-stickiness' => '1' },
    csr_mon_intr    => '20',
    csr_mon_timeout => '10',
    csr_timeout     => '60',
    service_name    => "p_${::neutron::params::dhcp_agent_service}",
  }

if ( 'ovs' in $ha_agents or 'ml2-ovs' in $ha_agents ) {
      cluster::corosync::cs_with_service {'dhcp-and-ovs':
      first   => "p_${::neutron::params::ovs_agent_service}",
      second  => "p_${::neutron::params::dhcp_agent_service}",
      require => Cluster::Corosync::Cs_service['ovs'],
    }
  }

  if 'metadata' in $ha_agents {
    cluster::corosync::cs_with_service {'dhcp-and-metadata':
      first   => "clone_p_${::neutron::params::metadata_agent_service}",
      second  => "p_${::neutron::params::dhcp_agent_service}",
      require => Cluster::Corosync::Cs_service['neutron-metadata-agent']
    }
  }

  Neutron::Agents::Dhcp {
    enabled         => false,
    manage_service  => false,
    before          => Cluster::Corosync::Cs_service['dhcp']
  }

}