if !$use_neutron {
  $floating_ips_range = hiera('floating_network_range')
  if $floating_ips_range {
    nova_floating_range{ $floating_ips_range:
      ensure          => 'present',
      pool            => 'nova',
      username        => $access_hash['user'],
      api_key         => $access_hash['password'],
      auth_method     => 'password',
      auth_url        => "http://${controller_node_address}:5000/v2.0/",
      authtenant_name => $access_hash['tenant'],
      api_retries     => '10',
    }
  }
}
