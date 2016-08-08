include ::openstack_tasks::horizon::horizon
Package<| |> { ensure => 'latest' } ~> Service<| |>
