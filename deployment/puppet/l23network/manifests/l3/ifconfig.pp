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
#   Specify network mask.
#
# [*ifname_order_prefix*]
#   Centos and Ubuntu at boot time Up and configure network interfaces in
#   alphabetical order of interface configuration file names.
#   This option helps You change this order at system startup.
#
# [*gateway*]
#   Specify default gateway if need.
#
# [*nameservers*]
#   Specify pair of nameservers if need.
#
# [*dhcp_hostname*]
#   Specify hostname for DHCP if need.
#
# [*dhcp_nowait*]
#   If you put 'true' to this option dhcp agent will be started in background.
#   Puppet will not wait for obtain IP address and route.
#
define l23network::l3::ifconfig (
    $interface       = $name,
    $ipaddr,
    $netmask         = '255.255.255.0',
    $gateway         = undef,
    $dns_nameservers = undef,
    $dns_search      = undef,
    $dns_domain      = undef,
    $dhcp_hostname   = undef,
    $dhcp_nowait     = false,
    $ifname_order_prefix = false
){

  case $ipaddr {
    'dhcp':  { $method = 'dhcp' }
    'none':  { $method = 'manual' }
    default: { $method = 'static' }
  }
  case $::osfamily {
    'Debian': {
      $if_files_dir = '/etc/network/interfaces.d'
      $interfaces = '/etc/network/interfaces'
      if $hwaddr { # Ubuntu need MAC addr in lower case
        $hwaddr_ok = downcase($hwaddr)
      }
      if $dns_nameservers {
        $dns_nameservers_join = join($dns_nameservers, ' ')
      }
    }
    'RedHat': {
      $if_files_dir = '/etc/sysconfig/network-scripts'
      $interfaces = false
      if $hwaddr { # RedHat need MAC addr in Upper case
        $hwaddr_ok = upcase($hwaddr)
      }
      if $dns_nameservers {
        $dns_nameservers_1 = $dns_nameservers[0]
        $dns_nameservers_2 = $dns_nameservers[1]
      }
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
  $cmd_ifup = 'ifup'
  $cmd_ifdn = 'ifdown'
  $cmd_flush= 'ip addr flush'

  if $ifname_order_prefix {
    $interface_file= "${if_files_dir}/ifcfg-${ifname_order_prefix}-${interface}"
  } else {
    $interface_file= "${if_files_dir}/ifcfg-${interface}"
  }

  if $interfaces {
    if ! defined(File[$interfaces]) {
      file {$interfaces:
        ensure  => present,
        content => template('l23network/interfaces.erb'),
      }
    }
    File[$interfaces] -> File[$if_files_dir]
  }

  if ! defined(File[$if_files_dir]) {
    file {$if_files_dir:
      ensure  => directory,
      owner   => 'root',
      mode    => '0755',
      recurse => true,
    }
  }

  file {$interface_file:
    ensure  => present,
    owner   => 'root',
    mode    => '0644',
    content => template("l23network/ipconfig_${::osfamily}_${method}.erb"),
    require => File[$if_files_dir],
  }

  # Downing interface
  exec { "ifdn_${interface}":
    command     => "${cmd_ifdn} ${interface}",
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    onlyif      => "ip link show ${interface} | grep ' ${interface}:' | grep -i ',UP,'",
    subscribe   => File[$interface_file],
    refreshonly => true,
  }
  # Cleaning interface
  exec { "flush_${interface}":
    command     => "${cmd_flush} ${interface}",
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    subscribe   => Exec["ifdn_${interface}"],
    refreshonly => true,
  }
  # Upping interface
  if $dhcp_nowait {
    $w = '&'
  } else {
    $w = ''
  }
  exec { "ifup_${interface}":
    command     => "${cmd_ifup} ${interface} ${w}",
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    subscribe   => Exec["flush_${interface}"],
    refreshonly => true,
  }
}
