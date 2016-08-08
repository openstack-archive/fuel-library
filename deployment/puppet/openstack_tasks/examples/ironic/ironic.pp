include ::openstack_tasks::ironic::ironic
Package<| |> { ensure => 'latest' } ~> Service<| |>
