include ::openstack_tasks::ceilometer::radosgw_user
Package<| |> { ensure => 'latest' } ~> Service<| |>
