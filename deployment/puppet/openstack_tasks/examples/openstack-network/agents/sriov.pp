class neutron {}
class { 'neutron' :}

include ::openstack_tasks::openstack_network::agents::sriov
Package<| |> { ensure => 'latest' }
