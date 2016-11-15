class { '::openstack_tasks::murano::rabbitmq' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
