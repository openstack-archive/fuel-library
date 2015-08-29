# == Define: l23network::l3::route

define l23network::l3::route (
    $destination,      # should be CIDR or 'default'
    $gateway,          # should be IP address
    $metric            = undef,
    $vendor_specific   = undef,
    $by_network_scheme = false,
    $provider          = undef,
    $ensure            = present,
) {
  include ::l23network::params

  $r_name = get_route_resource_name($destination, $metric)

  if ! defined (L3_route[$r_name]) {
    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }

    # There are no stored_config for this resource. Configure runtime only.
    l3_route { $r_name :
      ensure          => $ensure,
      destination     => $destination,
      gateway         => $gateway,
      metric          => $metric,
      vendor_specific => $vendor_specific,
      provider        => $provider  # For L3 features provider independed from OVS
    }
    if ! $by_network_scheme {
      L3_ifconfig<||> -> L3_route<||>
    }
  }
  Anchor['l23network::init'] -> L3_route<||>

}
