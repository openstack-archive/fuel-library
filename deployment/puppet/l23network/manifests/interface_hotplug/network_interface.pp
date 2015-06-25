# This define stops network-interface job instance
# for interface on Ubuntu OS that uses Upstart
# initialisation system

define l23network::interface_hotplug::network_interface (
  $interface = $title
) {
  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  # Stop network-interface job instance for interface
  service {"network-interface INTERFACE=${interface}":
    ensure   => stopped,
    provider => 'upstart',
    status   => "/sbin/initctl status network-interface INTERFACE=${interface}",
    start    => "/sbin/initctl start network-interface INTERFACE=${interface}",
    stop     => "/sbin/initctl stop network-interface INTERFACE=${interface}",
  }

  # Up interface manually
  exec {"up ${interface}":
    command => "ifup --allow auto ${interface}"
  }

  Service["network-interface INTERFACE=${interface}"] -> Exec["up ${interface}"]

}
