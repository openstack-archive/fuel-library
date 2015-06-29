# Class l23network::interface_hotplug disables the hotplug feature
# for network interfaces. Initially it is designed for Ubuntu OS
# which has this feature enabled by default.

class l23network::interface_hotplug (
  $disable = true,
)
{
  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  if $disable {
    if $::operatingsystem == 'Ubuntu' {
      $interface_array = split($::upstart_network_interface_instances, ',')

      # Stop network-interface job instance for every interface due to we can
      # not disable network-interface job if at least one instance exists
      l23network::interface_hotplug::network_interface { $interface_array: }

      # Disable network-inreface job
      exec {'disable-hotplug':
        command => 'mv /etc/init/network-interface.conf /etc/init/network-interface.disable',
        onlyif  => 'test -e /etc/init/network-interface.conf'
      }

      # Make config for loopback interface
      l23_stored_config { 'lo':
        ensure => 'present',
        ipaddr => '127.0.0.1/8',
        method => 'static',
        onboot => true,
      }

      L23network::Interface_hotplug::Network_interface<||> -> Exec['disable-hotplug'] -> L23_stored_config['lo']

    }
  }
}
