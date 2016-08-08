class neutron {}
class { 'neutron' :}

include ::openstack_tasks::openstack_network::agents::dhcp
Package<| |> { ensure => 'latest' }
