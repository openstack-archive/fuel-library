include ::openstack_tasks::aodh::aodh
Package<| |> { ensure => 'latest' } ~> Service<| |>
