class { '::openstack_tasks::openstack_cinder::openstack_cinder' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
