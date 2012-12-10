#
# This file does not seem to be used anywhere. Consider for deletion, or replace this comment with the actual usage description.
#

node default {
  notify { "test-notification-${hostname}": }
}

node /^(fuel-pm|fuel-cobbler).mirantis.com/ {

  class{cobbler::nat:
    nat_range => '10.0.0.0',
  }

  class { cobbler :
    server              => '10.0.0.100',

    domain_name         => 'your-domain-name.com',
    name_server         => '10.0.0.100',
    next_server         => '10.0.0.100',

    dhcp_start_address  => '10.0.0.201',
    dhcp_end_address    => '10.0.0.254',
    dhcp_netmask        => '255.255.255.0',
    dhcp_gateway        => '10.0.0.100',
    dhcp_interface      => 'eth1',

    cobbler_user        => 'cobbler',
    cobbler_password    => 'cobbler',

    pxetimeout          => '0'
  }

  # CENTOS distribution
  Class[cobbler::distro::centos63_x86_64] ->
  Class[cobbler::profile::centos63_x86_64]

  class { cobbler::distro::centos63_x86_64:
    http_iso => "http://10.0.0.1/iso/CentOS-6.3-x86_64-minimal.iso",
    ks_url   => "cobbler",
    require  => Class[cobbler],
  }

  class { cobbler::profile::centos63_x86_64: }


  # UBUNTU distribution
  Class[cobbler::distro::ubuntu_1204_x86_64] ->
  Class[cobbler::profile::ubuntu_1204_x86_64]

  class { cobbler::distro::ubuntu_1204_x86_64 :
    http_iso => "http://10.0.0.1/iso/ubuntu-12.04-x86_64-mini.iso",
    require  => Class[cobbler],
  }

  class { cobbler::profile::ubuntu_1204_x86_64 : }


  # RHEL distribution
  # Class[cobbler::distro::rhel63_x86_64] ->
  # Class[cobbler::profile::rhel63_x86_64]
  #
  # class { cobbler::distro::rhel63_x86_64:
  #   http_iso => "http://address/of/rhel-server-6.3-x86_64-boot.iso",
  #   ks_url   => "http://address/of/rhel/base/mirror/6.3/os/x86_64",
  #   require  => Class[cobbler],
  # }
  #
  # class { cobbler::profile::rhel63_x86_64: }

  class { cobbler::checksum_bootpc: }
  
  # IT IS NEEDED IN ORDER TO USE cobbler_system.py SCRIPT
  # WHICH USES argparse PYTHON MODULE
  package {"python-argparse": }

}
