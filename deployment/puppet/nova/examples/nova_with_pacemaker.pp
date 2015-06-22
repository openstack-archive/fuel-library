# Example: managing nova compute controller services with pacemaker
#
# By setting enabled to false, these services will not be started at boot.  By setting
# manage_service to false, puppet will not kill these services on every run.  This
# allows the Pacemaker resource manager to dynamically determine on which node each
# service should run.
#
# The puppet commands below would ideally be applied to at least three nodes.
#
# Note that nova-api and nova-novncproxy are associated with the virtual IP address as
# they are called from external services.  The remaining services connect to the
# database and/or message broker independently.
#
# Example pacemaker resource configuration commands (configured once per cluster):
#
# sudo pcs resource create nova_vip ocf:heartbeat:IPaddr2 params ip=192.0.2.3 \
#   cidr_netmask=24 op monitor interval=10s
#
# sudo pcs resource create nova_api_service lsb:openstack-nova-api
# sudo pcs resource create nova_conductor_service lsb:openstack-nova-conductor
# sudo pcs resource create nova_consoleauth_service lsb:openstack-nova-consoleauth
# sudo pcs resource create nova_novncproxy_service lsb:openstack-nova-novncproxy
# sudo pcs resource create nova_scheduler_service lsb:openstack-nova-scheduler
#
# sudo pcs constraint colocation add nova_api_service with nova_vip
# sudo pcs constraint colocation add nova_novncproxy_service with nova_vip

class { '::nova': }

class { '::nova::api':
  enabled        => false,
  manage_service => false,
  admin_password => 'PASSWORD',
}

class { '::nova::conductor':
  enabled        => false,
  manage_service => false,
}

class { '::nova::consoleauth':
  enabled        => false,
  manage_service => false,
}

class { '::nova::scheduler':
  enabled        => false,
  manage_service => false,
}

class { '::nova::vncproxy':
  enabled        => false,
  manage_service => false,
}

