### Cloud Controller:

# General Neutron stuff
# Configures everything in neutron.conf
class { 'neutron':
  verbose               => true,
  allow_overlapping_ips => true,
  rabbit_password       => 'password',
  rabbit_user           => 'guest',
  rabbit_host           => 'localhost',
  service_plugins       => ['metering']
}

# The API server talks to keystone for authorisation
class { 'neutron::server':
  keystone_password => 'password',
  connection        => 'mysql://neutron:password@192.168.1.1/neutron',
}

# Configure nova notifications system
class { 'neutron::server::notifications':
  nova_admin_tenant_name     => 'admin',
  nova_admin_password        => 'secrete',
}

# Various agents
class { 'neutron::agents::dhcp': }
class { 'neutron::agents::l3': }
class { 'neutron::agents::lbaas': }
class { 'neutron::agents::vpnaas': }
class { 'neutron::agents::metering': }

# This plugin configures Neutron for OVS on the server
# Agent
class { 'neutron::agents::ovs':
  local_ip         => '192.168.1.1',
  enable_tunneling => true,
}

# Plugin
class { 'neutron::plugins::ovs':
  tenant_network_type => 'gre',
}

# ml2 plugin with vxlan as ml2 driver and ovs as mechanism driver
class { 'neutron::plugins::ml2':
  type_drivers          => ['vxlan'],
  tenant_network_types  => ['vxlan'],
  vxlan_group           => '239.1.1.1',
  mechanism_drivers     => ['openvswitch'],
  vni_ranges            => ['0:300']
}

### Compute Nodes:
# Generally, any machine with a neutron element running on it talks
# over Rabbit and needs to know if overlapping IPs (namespaces) are in use
class { 'neutron':
  allow_overlapping_ips => true,
  rabbit_password       => 'password',
  rabbit_user           => 'guest',
  rabbit_host           => 'localhost',
}

# The agent/plugin combo also needs installed on clients
# Agent
class { 'neutron::agents::ovs':
  local_ip         => '192.168.1.11',
  enable_tunneling => true,
}

# Plugin
class { 'neutron::plugins::ovs':
  tenant_network_type => 'gre',
}
