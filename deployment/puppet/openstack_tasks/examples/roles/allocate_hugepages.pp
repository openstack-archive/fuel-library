include ::openstack_tasks::roles::allocate_hugepages
Package<| |> { ensure => 'latest' } ~> Service<| |>
