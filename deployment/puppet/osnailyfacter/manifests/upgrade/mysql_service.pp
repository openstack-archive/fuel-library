class osnailyfacter::upgrade::mysql_service {

  $mu_upgrade = hiera_hash('mu_upgrade', {})

  if $mu_upgrade['enabled'] and $mu_upgrade['restart_mysql'] {
    notify { 'restarting MySQL': } ~> Service <| title == 'mysqld' |>
  }

  notify { 'restarting non-MySQL services': } ~> Service <| title != 'mysqld' |>
}
