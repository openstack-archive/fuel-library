node default {

  class { cobbler::server:
    server              => $ipaddress,

    domain_name         => 'example.com',
    name_server         => $ipaddress,
    next_server         => $ipaddress,

    dhcp_start_address  => '10.100.0.201',
    dhcp_end_address    => '10.100.0.254',
    dhcp_netmask        => '255.255.255.0',
    dhcp_gateway        => '10.100.0.1',

    cobbler_user        => 'cobbler',
    cobbler_password    => 'cobbler',

    pxetimeout          => '0'
  }

  Class[cobbler::server] -> Class[cobbler::distro::centos63-x86_64]
  class { cobbler::distro::centos63-x86_64:
    centos_http_iso => "http://10.100.0.1/CentOS-6.3-x86_64-netinstall.iso"
  }

  Class[cobbler::distro::centos63-x86_64] -> Class[cobbler::profile::centos63-x86_64]
  class { cobbler::profile::centos63-x86_64:
    kickstart_repo_url => "http://172.18.8.52/~hex/centos/6.3/os/x86_64",
  }

  Class[cobbler::profile::centos63-x86_64] -> Cobbler_system["default"]
  cobbler_system { "default":
    profile => "centos63-x86_64",
    netboot => true,
  }
  
}
