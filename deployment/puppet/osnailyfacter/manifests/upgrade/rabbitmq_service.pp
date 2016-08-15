class osnailyfacter::upgrade::rabbitmq_service {

  $mu_upgrade = hiera_hash('mu_upgrade', {})

  if $mu_upgrade['enabled'] and $mu_upgrade['restart_rabbitmq'] {
    notify { 'restarting RabbitMQ': } ~> Service <| title == 'rabbitmq' |>
  }
  notify { 'restarting non-RabbitMQ services': } ~> Service <| title != 'rabbitmq' |>
}
