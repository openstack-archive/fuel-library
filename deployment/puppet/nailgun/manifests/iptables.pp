class nailgun::iptables {

  define access_to_nailgun_port($port, $protocol='tcp') {
    $rule = "-p $protocol -m state --state NEW -m $protocol --dport $port -j ACCEPT"
    exec { "access_to_nailgun_${protocol}_port: $port":
      command => "iptables -t filter -I INPUT 1 $rule; \
      /etc/init.d/iptables save",
      unless => "iptables -t filter -S INPUT | grep -q \"^-A INPUT $rule\""
    }
  }

  define ip_forward($network) {
    $rule = "-s $network -j MASQUERADE"
    exec { "ip_forward: $network":
      command => "iptables -t nat -I POSTROUTING 1 $rule; \
      /etc/init.d/iptables save",
      unless => "iptables -t nat -S POSTROUTING | grep -q \"^-A POSTROUTING $rule\""
    }
    sysctl::value{'net.ipv4.ip_forward': value=>'1'}
  }

  access_to_nailgun_port { "nailgun_web":    port => '8000' }
  access_to_nailgun_port { "nailgun_repo":    port => '8080' }
  $network_address = ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'],$::fuel_settings['ADMIN_NETWORK']['netmask'])
  $network_cidr = ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask'])
  ip_forward {'forward_slaves': network => "${network_address}/${network_cidr}"}
}
