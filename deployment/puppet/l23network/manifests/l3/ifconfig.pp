# == Define: l23network::l3::ifconfig
#
# Specify IP address for network interface and put interface to the UP state.
#
# === Parameters
#
# [*interface*]
#   Specify interface.
#
# [*ipaddr*]
#   IP address for interface. Can contain IP address, 'dhcp'
#   or 'none' (with no IP address).
#   Can be an array of CIDR IP addresses ['192.168.1.3/24','10.0.0.4/16']
#   for multiple IPs on an interface.
#
# [*gateway*]
#   Specify default gateway if need.
#   You can specify IP address, or 'save' for save default route
#   if it lies through this interface now.
#
## [*other_nets*]
##   Optional. Defines additional networks that this inteface can reach in CIDR
##   format.
##   It will be used to add additional routes to this interface.
##   other_nets => ['10.10.2.0/24', '10.10.4.0/24']
##
# [*dns_nameservers*]
#   Specify a pair of nameservers if need. Must be an array, for example:
#   nameservers => ['8.8.8.8', '8.8.4.4']
#
# [*dns_domain*]
#   Specify DOMAIN option for interface. Implemented for Ubuntu only.
#
# [*dns_search*]
#   Specify SEARCH option for interface. Must be an array, for example:
#   dns_search => ['aaaa.com', 'bbbb.org']
#
# [*dhcp_hostname*]
#   Specify hostname for DHCP if needed.
#
# [*dhcp_nowait*]
#   If you set this parameter as 'true' dhcp agent will start on the background.
#   Puppet will not wait for obtaining IP address and routes.
#
# [*check_by_ping*]
#   You can set an IP address that will be pinged when interface is UP.
#   The given IP will be checked during the check_by_ping_timeout.
#   Can be any IP address, 'none' or 'gateway' for checking the availability of
#   default gateway if it is set for this interface.
#
# [*check_by_ping_timeout*]
#   Timeout for check_by_ping
#

define l23network::l3::ifconfig (
    $ensure          = present,
    $interface       = $name,
    $ipaddr          = undef,
    $gateway         = undef,
    $gateway_metric  = undef,
    $dns_nameservers = undef,
    $dns_search      = undef,
    $dns_domain      = undef,
    $dhcp_hostname   = undef,
    $check_by_ping   = 'gateway',
    $check_by_ping_timeout = 30,
    #todo: label => "XXX", # -- "ip addr add..... label XXX"
    $vendor_specific = undef,
    $provider        = undef
) {
  include ::stdlib
  include ::l23network::params

  # setup configure method for inteface
  if is_array($ipaddr) {
    # getting array of IP addresses for one interface
    $method = 'static'
    check_cidrs($ipaddr)
    $ipaddr_list    = $ipaddr
    $ipaddr_aliases = array_part($ipaddr_list,1,0)
    #$ipaddr_aliases    = split(inline_template("<%= @ipaddr_list[1..-1].join(':')%>"),':')
  } elsif is_string($ipaddr) {
    # getting single IP address for interface. It can be not address, but method.
    $ipaddr_aliases = undef
    case $ipaddr {
      'dhcp':  {
        $method      = 'dhcp'
        $ipaddr_list = ['dhcp']
      }
      'none':  {
        $method      = 'manual'
        $ipaddr_list = ['none']
      }
      default: {
        $method      = 'static'
        $ipaddr_list = [$ipaddr]
      }
    }
  } else {
    fail('Ipaddr must be a single IPaddr or list of IPaddrs in CIDR notation.')
  }

  # DNS nameservers, search and domain options
  if $dns_nameservers {
    $dns_nameservers_list = concat(array_or_string_to_array($dns_nameservers), [false, false])
    $dns_nameservers_1 = $dns_nameservers_list[0]
    $dns_nameservers_2 = $dns_nameservers_list[1]
  }
  if $dns_search {
    $dns_search_list = array_or_string_to_array($dns_search)
    if $dns_search_list {
      $dns_search_string = join($dns_search_list, ' ')
    } else {
      fail('dns_search option must be array or string')
    }
  }
  if $dns_domain {
    $dns_domain_list = array_or_string_to_array($dns_domain)
    if $dns_domain_list {
      $dns_domain_string = $dns_domain_list[0]
    } else {
      fail('dns_domain option must be array or string')
    }
  }

  if $method == 'static' {
    $def_gateway = $gateway
    # # todo: move routing to separated resource with his own provider
    # if ($def_gateway and !defined(L23network::L3::Defaultroute[$def_gateway])) {
    #   Anchor['l23network::init'] ->
    #   L3_ifconfig[$interface]
    #   ->
    #   l23network::l3::defaultroute { $def_gateway: }
    # }
  } else {
    $def_gateway = undef
  }

  if ! defined (L3_ifconfig[$interface]) {
    if $provider {
      $config_provider = "${provider}_${::l23_os}"
    } else {
      $config_provider = undef
    }


    if !defined(L23network::L2::Port[$interface]) and !defined(L23network::L2::Bond[$interface]) and !defined(L23network::L2::Bridge[$interface]) {
      l23network::l2::port { $interface: }
      L23network::L2::Port[$interface] -> L3_ifconfig[$interface]
    } elsif defined(L23network::L2::Port[$interface]) {
      L23network::L2::Port[$interface] -> L3_ifconfig[$interface]
    } elsif defined(L23network::L2::Bond[$interface]) {
      L23network::L2::Bond[$interface] -> L3_ifconfig[$interface]
    } elsif defined(L23network::L2::Bridge[$interface]) {
      L23network::L2::Bridge[$interface] -> L3_ifconfig[$interface]
    }

    if ! defined (L23_stored_config[$interface]) {
      l23_stored_config { $interface:
        provider     => $config_provider
      }
    }
    L23_stored_config <| title == $interface |> {
      method          => $method,
      ipaddr          => $ipaddr_list[0],
      ipaddr_aliases  => $ipaddr_aliases,
      gateway         => $def_gateway,
      gateway_metric  => $gateway_metric,
      vendor_specific => $vendor_specific,
      #provider      => $config_provider  # do not enable, provider should be set while port define
    }

    # configure runtime
    l3_ifconfig { $interface :
      ensure                => $ensure,
      ipaddr                => $ipaddr_list,
      gateway               => $def_gateway,
      gateway_metric        => $gateway_metric,
##    $other_nets           = undef,
#     dns_nameservers       => $dns_nameservers,
#     dns_search            => $dns_search_string,
#     dns_domain            => $dns_domain_string,
#     dhcp_hostname         => $dhcp_hostname,
#     check_by_ping         => $check_by_ping,
#     check_by_ping_timeout => $check_by_ping_timeout,
      vendor_specific       => $vendor_specific,
      provider              => $provider  # For L3 features provider independed from OVS
    }

    L23_stored_config <| title == $interface |> ->
    L3_ifconfig <| title == $interface |>
  }
}
