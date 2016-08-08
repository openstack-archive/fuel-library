include ::openstack_tasks::openstack_cinder::openstack_cinder
Package<| |> { ensure => 'latest' } ~> Service<| |>
