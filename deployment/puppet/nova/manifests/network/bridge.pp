# bridge.pp
define nova::network::bridge (
  $ip,
  $netmask = '255.255.255.0'
) {

  case $::osfamily {

    'Debian': {
      $context = '/files/etc/network/interfaces'
      augeas { "bridge_${name}":
        context => $context,
        changes => [
          "set auto[child::1 = '${name}']/1 ${name}",
          "set iface[. = '${name}'] ${name}",
          "set iface[. = '${name}']/family inet",
          "set iface[. = '${name}']/method static",
          "set iface[. = '${name}']/address ${ip}",
          "set iface[. = '${name}']/netmask ${netmask}",
          "set iface[. = '${name}']/bridge_ports none",
        ],
        notify  => Exec['networking-refresh'],
      }
    }

    'RedHat' : {
    }

    default: { fail('nova::network_bridge currently only supports osfamily Debian and RedHat') }

  }
}
