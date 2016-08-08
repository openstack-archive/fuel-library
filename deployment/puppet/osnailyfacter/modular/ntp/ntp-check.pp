include ::osnailyfacter::ntp::ntp_check
Package<| |> { ensure => 'latest' } ~> Service<| |>
