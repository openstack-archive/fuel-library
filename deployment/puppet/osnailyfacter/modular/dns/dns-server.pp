include ::osnailyfacter::dns::dns_server
Package<| |> { ensure => 'latest' } ~> Service<| |>
