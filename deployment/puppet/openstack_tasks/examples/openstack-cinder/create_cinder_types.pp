include ::openstack_tasks::openstack_cinder::create_cinder_types
Package<| |> { ensure => 'latest' } ~> Service<| |>
