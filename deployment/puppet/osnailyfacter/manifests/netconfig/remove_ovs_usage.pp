class osnailyfacter::netconfig::remove_ovs_usage {
  notice('MODULAR: netconfig/remove_ovs_usage.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  $overrides      = remove_ovs_usage($network_scheme)

  file {"/etc/hiera/override/configuration/remove_ovs_usage.yaml":
    ensure  => file,
    content => inline_template("<%= @overrides %>")
  }
}
