class neutron {}
class { 'neutron' :}

include ::openstack_tasks::openstack_network::agents::metadata
Package<| |> { ensure => 'latest' }
