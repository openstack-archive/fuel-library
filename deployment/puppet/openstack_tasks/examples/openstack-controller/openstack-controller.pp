class { '::openstack_tasks::openstack_controller::openstack_controller' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
