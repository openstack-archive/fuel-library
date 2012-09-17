node default {

  class { cobbler::server:
      next_server      => $ipaddress,
      server           => $ipaddress,
      domain           => 'example.com',
      dhcp_range       => '10.100.0.220,10.100.0.230',
      gateway          => '10.100.0.1',
      cobbler_user     => 'cobbler',
      cobbler_password => 'cobbler',
      pxetimeout       => '0'
  }

  Class[cobbler::server] -> Class[cobbler::distro::centos63-x86_64]
  class { cobbler::distro::centos63-x86_64:
    centos_http_iso => "http://10.100.0.1/CentOS-6.3-x86_64-netinstall.iso"
  }

  Class[cobbler::distro::centos63-x86_64] -> Class[cobbler::profile::centos63-x86_64]
  class { cobbler::profile::centos63-x86_64: }

  Class[cobbler::profile::centos63-x86_64] -> Cobbler_system["default"]
  cobbler_system { "default":
    profile => "centos63-x86_64",
    netboot => true,
  }
  
}
