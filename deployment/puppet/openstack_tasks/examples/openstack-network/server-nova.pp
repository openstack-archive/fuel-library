include ::openstack_tasks::openstack_network::server_nova
Package<| |> { ensure => 'latest' } ~> Service<| |>
