include ::openstack_tasks::openstack_controller::keystone
Package<| |> { ensure => 'latest' } ~> Service<| |>
