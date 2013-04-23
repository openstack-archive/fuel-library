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
#   IP address for interface. Can contains IP address, 'dhcp', or 'none'
#   for up empty unaddressed interface.
#
# [*netmask*]
#   Specify network mask. Default is '255.255.255.0'.
#
# [*vlandev*]
#   If you configure 802.1q vlan interface wint name vlanXXX
#   you must specify parent interface in this option
#
# [*bond_master*]
#   This option say, that this interface is a slave of bondX interface.
#
# [*bond_mode*]
#   For interfaces bondNN this option specified bond mode.
#   All bond_* properties ignored for non-master-bond interfaces.
#
# [*bond_miimon*]
#   lacp MII monitor period.
#
# [*bond_lacp_rate*]
#   lacp MII rate
#
# [*ifname_order_prefix*]
#   Centos and Ubuntu at boot time Up and configure network interfaces in
#   alphabetical order of interface configuration file names.
#   This option helps You change this order at system startup.
#
# [*gateway*]
#   Specify default gateway if need.
#
# [*dns_nameservers*]
#   Specify pair of nameservers if need. Must be array, for example:
#   nameservers => ['8.8.8.8', '8.8.4.4']
#
# [*dns_domain*]
#   Specify DOMAIN option for interface. Implemened only in ubuntu.
#
# [*dns_search*]
#   Specify SEARCH option for interface. Must be array, for example:
#   dns_search => ['aaaa.com', 'bbbb.org']
#
# [*dhcp_hostname*]
#   Specify hostname for DHCP if need.
#
# [*dhcp_nowait*]
#   If you put 'true' to this option dhcp agent will be started in background.
#   Puppet will not wait for obtain IP address and route.
#
# [*check_by_ping*]
#   You can put here IP address, that will be pinged after interface UP. We will
#   be wait that this IP will pinged.
#   Can be IP address, 'none', or 'gateway' for check awailability default gateway
#   if it exists for this interface.
#
# [*check_by_ping_timeout*]
#   Timeout for check_by_ping
#
#
# If You configure 802.1q vlan interfaces -- You must declare relationships between
# them in site.pp.
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
    $dns_nameservers = undef,
    $dns_search      = undef,
    $dns_domain      = undef,
    $dhcp_hostname   = undef,
    $dhcp_nowait     = false,
    $ifname_order_prefix = false,
    $check_by_ping   = 'gateway',
    $check_by_ping_timeout = 120,
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

  # calculate effective_netmask
  #todo: if ipaddr given in CIDR mode (A.B.C.D/E) -- ignore netmask and calculate effective_netmask from CIDR
  $effective_netmask = $netmask
  #todo: calculate CIDR netmask /XX

  # setup configure method for inteface
  if $bond_master {
    $method = 'bondslave'
  } else {
    case $ipaddr {
      'dhcp':  { $method = 'dhcp' }
      'none':  { $method = 'manual' }
      default: { $method = 'static' }
    }
  }

  # OS depends constats and packages
  case $::osfamily {
    /(?i)debian/: {
      $if_files_dir = '/etc/network/interfaces.d'
      $interfaces = '/etc/network/interfaces'
    }
    /(?i)redhat/: {
      $if_files_dir = '/etc/sysconfig/network-scripts'
      $interfaces = false
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
      if ! $bond_mode or $bond_mode <0 or $bond_mode>6 {
        fail("You configure interface bonding. In this mode option bond_mode required, and must be between 0..6, not '${bond_mode}'.")
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
    if $gateway {
      $def_gateway = $gateway
    } else {
      if $::l3_default_route and $::l3_default_route_interface == $interface {
        $def_gateway = $::l3_default_route
      } else {
        $def_gateway = undef
      }
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

  notify {"ifconfig_${interface}": message=>"Interface:${interface} IP:${ipaddr}/${effective_netmask}", withpath=>false} ->
  l3_if_downup {"$interface":
    check_by_ping => $check_by_ping,
    check_by_ping_timeout => $check_by_ping_timeout,
    subscribe     => File["$interface_file"],
    refreshonly   => true,
  }
}
