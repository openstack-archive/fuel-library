include ::openstack_tasks::openstack_network::routers
Package<| |> { ensure => 'latest' } ~> Service<| |>
