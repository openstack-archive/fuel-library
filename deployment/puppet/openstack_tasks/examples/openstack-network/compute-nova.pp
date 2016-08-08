include ::openstack_tasks::openstack_network::compute_nova
Package<| |> { ensure => 'latest' } ~> Service<| |>
