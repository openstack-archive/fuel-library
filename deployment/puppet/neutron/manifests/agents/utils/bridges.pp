define neutron::agents::utils::bridges {
  $bridge = $name
  if !defined(L23network::L2::Bridge[$bridge]) {
    l23network::l2::bridge {$bridge:
      ensure        => present,
      external_ids  => "bridge-id=${bridge}",
      skip_existing => true,
    }
  }
}

# vim: set ts=2 sw=2 et :