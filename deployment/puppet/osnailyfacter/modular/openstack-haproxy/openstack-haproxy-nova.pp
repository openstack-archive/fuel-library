include ::osnailyfacter::openstack_haproxy::openstack_haproxy_nova
Package<| |> { ensure => 'latest' } ~> Service<| |>
