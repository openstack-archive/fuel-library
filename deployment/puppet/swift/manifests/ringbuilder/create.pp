define swift::ringbuilder::create(
  $part_power = 18,
  $replicas = 5,
  $min_part_hours = 1
) {

  validate_re($name, '^object|container|account$')

  exec { "create_${name}":
    command     => "swift-ring-builder /etc/swift/${name}.builder create ${part_power} ${replicas} ${min_part_hours}",
    path        => ['/usr/bin'],
    creates     => "/etc/swift/${name}.builder",
  }

}
