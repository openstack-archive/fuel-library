include ::osnailyfacter::fuel_pkgs::setup_repositories
Package<| |> { ensure => 'latest' } ~> Service<| |>
