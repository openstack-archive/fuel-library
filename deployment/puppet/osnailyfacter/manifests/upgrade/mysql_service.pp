class osnailyfacter::upgrade::mysql_service {

  $mu_upgrade = hiera_hash('mu_upgrade', {})

  if $mu_upgrade['enabled'] and $mu_upgrade['restart_mysql'] {
    # Restart all services in puppet catalog only if restart_mysql
    # is true. If we try to restart non-mysql services they could
    # trigger MySQL to restart as well.
    notify { 'restarting MySQL DB services': } ~> Service <||>
  }
}
