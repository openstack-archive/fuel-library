class neutron { }
class { 'neutron' : }

include ::openstack_tasks::openstack_network::server_config
Package<| |> { ensure => 'latest' }
