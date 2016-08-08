include ::openstack_tasks::openstack_controller::openstack_controller
Package<| |> { ensure => 'latest' } ~> Service<| |>
