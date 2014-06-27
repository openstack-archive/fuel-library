# Example: managing neutron controller services with pacemaker
#
# By setting enabled to false, these services will not be started at boot.  By setting
# manage_service to false, puppet will not kill these services on every run.  This
# allows the Pacemaker resource manager to dynamically determine on which node each
# service should run.
#
# The puppet commands below would ideally be applied to at least three nodes.
#
# Note that neutron-server is associated with the virtual IP address as
# it is called from external services.  The remaining services connect to the
# database and/or message broker independently.
#
# Example pacemaker resource configuration commands (configured once per cluster):
#
# sudo pcs resource create neutron_vip ocf:heartbeat:IPaddr2 params ip=192.0.2.3 \
#   cidr_netmask=24 op monitor interval=10s
#
# sudo pcs resource create neutron_server_service lsb:neutron-server
# sudo pcs resource create neutron_dhcp_agent_service lsb:neutron-dhcp-agent
# sudo pcs resource create neutron_l3_agent_service lsb:neutron-l3-agent
#
# sudo pcs constraint colocation add neutron_server_service with neutron_vip

class { 'neutron':
  verbose               => true,
  allow_overlapping_ips => true,
  service_plugins       => [ 'dhcp', 'l3' ]
}

class { 'neutron::server':
  enabled           => false,
  manage_service    => false,
  keystone_password => 'password',
  connection        => 'mysql://neutron:password@192.168.1.1/neutron',
}

class { 'neutron::agents::dhcp':
  enabled        => false,
  manage_service => false,
}

class { 'neutron::agents::l3':
  enabled        => false,
  manage_service => false,
}

