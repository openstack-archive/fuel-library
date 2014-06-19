# Example: managing cinder controller services with pacemaker
#
# By setting enabled to false, these services will not be started at boot.  By setting
# manage_service to false, puppet will not kill these services on every run.  This
# allows the Pacemaker resource manager to dynamically determine on which node each
# service should run.
#
# The puppet commands below would ideally be applied to at least three nodes.
#
# Note that cinder-api is associated with the virtual IP address as
# it is called from external services.  The remaining services connect to the
# database and/or message broker independently.
#
# Example pacemaker resource configuration commands (configured once per cluster):
#
# sudo pcs resource create cinder_vip ocf:heartbeat:IPaddr2 params ip=192.0.2.3 \
#   cidr_netmask=24 op monitor interval=10s
#
# sudo pcs resource create cinder_api_service lsb:openstack-cinder-api
# sudo pcs resource create cinder_scheduler_service lsb:openstack-cinder-scheduler
#
# sudo pcs constraint colocation add cinder_api_service with cinder_vip

class { 'cinder':
  database_connection  => 'mysql://cinder:secret_block_password@openstack-controller.example.com/cinder',
}

class { 'cinder::api':
  keystone_password => 'CINDER_PW',
  keystone_user     => 'cinder',
  enabled           => false,
  manage_service    => false,
}

class { 'cinder::scheduler':
  scheduler_driver => 'cinder.scheduler.simple.SimpleScheduler',
  enabled          => false,
  manage_service   => false,
}

