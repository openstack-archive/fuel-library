define quantum::plugins::ovs::bridge {
  $mapping = split($name, ":")
  $bridge = $mapping[1]

  if !defined(l23network::l2::bridge[$bridge]) {
    l23network::l2::bridge {$bridge:
      ensure        => present,
      external_ids  => "bridge-id=${bridge}",
      skip_existing => true,
    }
  }
}
