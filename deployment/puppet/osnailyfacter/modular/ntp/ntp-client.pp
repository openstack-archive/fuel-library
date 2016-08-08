include ::osnailyfacter::ntp::ntp_client
Package<| |> { ensure => 'latest' } ~> Service<| |>
