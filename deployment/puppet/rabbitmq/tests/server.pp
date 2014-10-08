class { 'rabbitmq::server':
  port              => '5672',
  delete_guest_user => true,
  # NOTE(bogdando) patching feature assumes 'installed'
  version           => 'latest',
}
