class osnailyfacter::upgrade::ceph_service {

  $mu_upgrade = hiera_hash('mu_upgrade', {})

  if $mu_upgrade['enabled'] and $mu_upgrade['restart_ceph'] {
    # Restart all services in puppet catalog only if restart_ceph
    # is true. If we try to restart non-ceph services they could
    # trigger Ceph to restart as well.
    notify { 'restarting Ceph': } ~> Service <||>
  }
}
