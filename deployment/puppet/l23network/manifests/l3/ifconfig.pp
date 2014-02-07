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
#   for multiple IPs on an interface. In this case netmask parameter is ignored.
#
# [*netmask*]
#   Specify network mask. Default is '255.255.255.0'.
#
# [*macaddr*]
#   Specify macaddr if need change.
#
# [*vlandev*]
#   If you configure 802.1q vlan interface with name like 'vlanXXX'
#   you must specify a parent interface in this option
#
# [*bond_master*]
#   This parameter sets the bond_master interface and says that this interface
#   is a slave for bondX interface.
#
# [*bond_mode*]
#   This parameter specifies a bond mode for interfaces like bondNN.
#   All bond_* properties are ignored for non-bond-master interfaces.
#
# [*bond_miimon*]
#   lacp MII monitor period.
#
# [*bond_lacp_rate*]
#   lacp MII rate
#
# [*ifname_order_prefix*]
#    Sets the interface startup order
#
# [*gateway*]
#   Specify default gateway if need.
#   You can specify IP address, or 'save' for save default route
#   if it lies through this interface now.
#
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
#
# If you configure 802.1q vlan interfaces then you must declare relationships
# between them in site.pp.
# Ex: L23network:L3:Ifconfig['eth2'] -> L23network:L3:Ifconfig['eth2.128']
#
define l23network::l3::ifconfig (
    $ipaddr,
    $interface       = $name,
    $netmask         = '255.255.255.0',
    $gateway         = undef,
    $vlandev         = undef,
    $bond_master     = undef,
    $bond_mode       = undef,
    $bond_miimon     = 100,
    $bond_lacp_rate  = 1,
    $mtu             = undef,
    $macaddr         = undef,
    $dns_nameservers = undef,
    $dns_search      = undef,
    $dns_domain      = undef,
    $dhcp_hostname   = undef,
    $dhcp_nowait     = false,
    $ifname_order_prefix = false,
    $check_by_ping   = 'gateway',
    $check_by_ping_timeout = 30,
    #todo: label => "XXX", # -- "ip addr add..... label XXX"
){
  include ::l23network::params

  $bond_modes = [
    'balance-rr',
    'active-backup',
    'balance-xor',
    'broadcast',
    '802.3ad',
    'balance-tlb',
    'balance-alb'
  ]

  if $macaddr and $macaddr !~ /^([0-9a-fA-F]{2}\:){5}[0-9a-fA-F]{2}$/ {
    fail("Invalid MAC address '${macaddr}' for interface '${interface}'")
  }

  if $mtu and !is_integer("${mtu}") {  # is_integer() fails if integer given :)
    fail("Invalid MTU '${mtu}' for interface '${interface}'")
  }

  # setup configure method for inteface
  if $bond_master {
    $method = 'bondslave'
  } elsif is_array($ipaddr) {
    # getting array of IP addresses for one interface
    $method = 'static'
    check_cidrs($ipaddr)
    $effective_ipaddr  = cidr_to_ipaddr($ipaddr[0])
    $effective_netmask = cidr_to_netmask($ipaddr[0])
    $ipaddr_aliases    = array_part($ipaddr,1,0)
  } elsif is_string($ipaddr) {
    # getting single IP address for interface. It can be not address, but method.
    $ipaddr_aliases = undef
    case $ipaddr {
      'dhcp':  {
        $method = 'dhcp'
        $effective_ipaddr  = $ipaddr
        $effective_netmask = undef
      }
      'none':  {
        $method = 'manual'
        $effective_ipaddr  = $ipaddr
        $effective_netmask = undef
      }
      default: {
        $method = 'static'
        if $ipaddr =~ /\/\d{1,2}\s*$/ {
          # ipaddr can be cidr-notated
          $effective_ipaddr = cidr_to_ipaddr($ipaddr)
          $effective_netmask = cidr_to_netmask($ipaddr)
        } else {
          # or classic pair of ipaddr+netmask
          $effective_ipaddr = $ipaddr
          $effective_netmask = $netmask
        }
      }
    }
  } else {
    fail("Ipaddr must be a string or array of strings")
  }

  # OS dependent constants and packages
  case $::osfamily {
    /(?i)debian/: {
      $if_files_dir = '/etc/network/interfaces.d'
      $interfaces = '/etc/network/interfaces'
    }
    /(?i)redhat/: {
      $if_files_dir = '/etc/sysconfig/network-scripts'
      $interfaces = false
      if ! defined(Class[L23network::L2::Centos_upndown_scripts]) {
        if defined(Stage[netconfig]) {
          class{'l23network::l2::centos_upndown_scripts': stage=>'netconfig' }
        } else {
          class{'l23network::l2::centos_upndown_scripts': }
        }
      }
      Anchor <| title == 'l23network::l2::centos_upndown_scripts' |>
        -> L23network::L3::Ifconfig <| interface == "$interface" |>
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }

  # DNS nameservers, search and domain options
  if $dns_nameservers {
    $dns_nameservers_list = merge_arrays( array_or_string_to_array($dns_nameservers), [false, false])
    $dns_nameservers_1 = $dns_nameservers_list[0]
    $dns_nameservers_2 = $dns_nameservers_list[1]
  }
  if $dns_search {
    $dns_search_list = array_or_string_to_array($dns_search)
    if $dns_search_list {
      $dns_search_string = join($dns_search_list, ' ')
    } else {
      fail("dns_search option must be array or string")
    }
  }
  if $dns_domain {
    $dns_domain_list = array_or_string_to_array($dns_domain)
    if $dns_domain_list {
      $dns_domain_string = $dns_domain_list[0]
    } else {
      fail("dns_domain option must be array or string")
    }
  }

  # Detect VLAN and bond mode configuration
  case $interface {
    /^vlan(\d+)/: {
      $vlan_mode = 'vlan'
      $vlan_id   = $1
      if $vlandev {
        $vlan_dev = $vlandev
      } else {
        fail("Can't configure vlan interface ${interface} without definition (ex: vlandev=>ethXX).")
      }
    }
    /^(eth\d+)\.(\d+)/: { # TODO: bond0.123 -- also vlan
      $vlan_mode = 'eth'
      $vlan_id   = $2
      $vlan_dev  = $1
    }
    /^(bond\d+)/: {
      if ! $bond_mode {
        fail("To configure the interface bonding you must the bond_mode parameter is required and must be between 0..6.")
      }
      if $bond_mode <0 or $bond_mode>6 {
        fail("For interface bonding the bond_mode must be between 0..6, not '${bond_mode}'.")
      }
      $vlan_mode = undef
    }
    default: {
      $vlan_mode = undef
    }
  }

  # Specify interface file name prefix
  if $ifname_order_prefix {
    $interface_file= "${if_files_dir}/ifcfg-${ifname_order_prefix}-${interface}"
  } else {
    $interface_file= "${if_files_dir}/ifcfg-${interface}"
  }

  if $method == 'static' {
    if $gateway and $gateway != 'save' {
      $def_gateway = $gateway
    } else {
      # recognizing default gateway
      if $gateway == 'save' and $::l3_default_route and $::l3_default_route_interface == $interface {
        $def_gateway = $::l3_default_route
      } else {
        $def_gateway = undef
      }
    }
    if ($::osfamily == 'RedHat' or $::osfamily == 'Debian') and $def_gateway and !defined(L23network::L3::Defaultroute[$def_gateway]) {
      l23network::l3::defaultroute { $def_gateway: }
    }
  } else {
    $def_gateway = undef
  }

  if $interfaces {
    if ! defined(File["$interfaces"]) {
      file {"$interfaces":
        ensure  => present,
        content => template('l23network/interfaces.erb'),
      }
    }
    File<| title == "$interfaces" |> -> File<| title == "$if_files_dir" |>
  }

  if ! defined(File["$if_files_dir"]) {
    file {"$if_files_dir":
      ensure  => directory,
      owner   => 'root',
      mode    => '0755',
      recurse => true,
    }
  }
  File<| title == "$if_files_dir" |> -> File<| title == "$interface_file" |>

  file {"$interface_file":
    ensure  => present,
    owner   => 'root',
    mode    => '0644',
    content => template("l23network/ipconfig_${::osfamily}_${method}.erb"),
  }
  if $::osfamily =~ /(?i)redhat/ and $ipaddr_aliases {
    file {"${if_files_dir}/interface-up-script-${interface}":
      ensure  => present,
      owner   => 'root',
      mode    => '0755',
      recurse => true,
      content => template("l23network/ipconfig_${::osfamily}_${method}_up-script.erb"),
    } ->
    File <| title == $interface_file |>
  }

  notify {"ifconfig_${interface}": message=>"Interface:${interface} IP:${effective_ipaddr}/${effective_netmask}", withpath=>false} ->
  l3_if_downup {"$interface":
    check_by_ping => $check_by_ping,
    check_by_ping_timeout => $check_by_ping_timeout,
    #require       => File["$interface_file"], ## do not enable it!!! It affect requirements interface from interface in some cases.
    subscribe     => File["$interface_file"],
    refreshonly   => true,
  }

}
