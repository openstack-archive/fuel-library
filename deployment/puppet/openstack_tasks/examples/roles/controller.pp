class { '::openstack_tasks::roles::controller' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
