# == Define: l23network::l3::route

define l23network::l3::route (
    $network,        # should be CIDR or 'default'
    $gateway,        # should be IP address
    $metric          = undef,
    $vendor_specific = undef,
    $provider        = undef,
    $ensure          = present,
) {
  include ::l23network::params

  if $metric {  # is_integer($metric)
    $r_name = "${network},metric:${$metric}"
  } else {
    $r_name = "${network}"
  }

  if ! defined (L3_route[$r_name]) {
    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }

    # if ! defined (L23_stored_config[$interface]) {
    #   l23_stored_config { $interface:
    #     provider     => $config_provider
    #   }
    # }
    # L23_stored_config <| title == $interface |> {
    #   method          => $method,
    #   ipaddr          => $ipaddr_list[0],
    #   gateway         => $def_gateway,
    #   gateway_metric  => $gateway_metric,
    #   vendor_specific => $vendor_specific,
    #   #provider      => $config_provider  # do not enable, provider should be set while port define
    # }

    # configure runtime
    l3_route { $r_name :
      ensure          => $ensure,
      network         => $network,
      gateway         => $gateway,
      metric          => $metric,
      vendor_specific => $vendor_specific,
      provider        => $provider  # For L3 features provider independed from OVS
    }
    L3_ifconfig<||> -> L3_route<||>
  }

}
