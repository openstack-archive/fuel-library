class osnailyfacter::upgrade::rabbitmq_service {

  $mu_upgrade = hiera_hash('mu_upgrade', {})

  if $mu_upgrade['enabled'] and $mu_upgrade['restart_rabbitmq'] {
    # Restart all services in puppet catalog only if restart_rabbitmq
    # is true. If we try to restart non-rabbitmq services they could
    # trigger RabbitMQ to restart as well.
    notify { 'restarting RabbitMQ': } ~> Service <||>
  }
}
