class neutron {}
class { 'neutron' :}
class { '::openstack_tasks::openstack_network::agents::dhcp' :}
class { '::osnailyfacter::upgrade::restart_services' :}
class { '::osnailyfacter::override_resources': }
