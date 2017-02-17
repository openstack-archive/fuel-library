class provision::params {
  case $::osfamily {
    'RedHat': {
      $dhcpd_package    = "dhcp"
      $dhcpd_service    = "dhcpd"
      $dhcpd_conf       = "/etc/dhcp/dhcpd.conf"
      $dhcpd_conf_d     = "/etc/dhcp/dhcpd.d"
      $dhcpd_conf_extra = "/etc/dhcp/dhcpd.d/extra.conf"
      $named_package    = "bind"
      $named_service    = "named"
      $named_conf       = "/etc/named.conf"
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }
  $network_address = "10.20.0.0"
  $network_mask = "255.255.255.0"
  $broadcast_address = "10.20.0.255"
  $start_address = "10.20.0.3"
  $end_address = "10.20.0.254"
  $router = "10.20.0.1"
  $next_server = "10.20.0.2"
  $dns_address = "10.20.0.2"
  $forwarders = ["8.8.8.8", "8.8.4.4"]
  $domain_name = "domain.tld"
  $ddns_key = "VyCWe0kutrawqQ2WEFKkAw=="
  $ddns_key_algorithm = "HMAC-MD5"
  $ddns_key_name = "DHCP_UPDATE"

  $bootstrap_kernel_path = "/images/ubuntu_bootstrap/vmlinuz"
  $bootstrap_initrd_path = "/images/ubuntu_bootstrap/initrd.img"
  $bootstrap_kernel_params = "ksdevice=bootif lang= console=ttyS0,9600 console=tty0 toram locale=en_US text boot=live biosdevname=0 components ip=frommedia ethdevice-timeout=120 net.ifnames=1 panic=60"
  $bootstrap_menu_label = "ubuntu_bootstrap"

}
