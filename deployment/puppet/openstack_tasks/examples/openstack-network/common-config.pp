include ::openstack_tasks::openstack_network::common_config
Package<| |> { ensure => 'latest' } ~> Service<| |>
