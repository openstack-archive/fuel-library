include ::openstack_tasks::openstack_network::keystone
Package<| |> { ensure => 'latest' } ~> Service<| |>
