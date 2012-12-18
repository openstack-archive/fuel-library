#
# This manifest file is being used as a sample in Fuel user guide.
#
# It's a starting point for an end-user.
# User has to edit this file and change networking information, as well as uncomment/edit corresponding sections for CentOS, Ubuntu, and RHEL.
#

$server              = '10.0.0.100'
$domain_name         = 'your-domain-name.com'
$name_server         = '10.0.0.100'
$next_server         = '10.0.0.100'
$dhcp_start_address  = '10.0.0.201'
$dhcp_end_address    = '10.0.0.254'
$dhcp_netmask        = '255.255.255.0'
$dhcp_gateway        = '10.0.0.100'
$cobbler_user        = 'cobbler'
$cobbler_password    = 'cobbler'
$pxetimeout          = '0'
$dhcp_interface      = 'eth1'

stage {'openstack-custom-repo': before => Stage['main']}
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo' }

node fuel-pm {
  class { cobbler:
    server              => $server,

    domain_name         => $domain_name,
    name_server         => $name_server,
    next_server         => $next_server,

    dhcp_start_address  => $dhcp_start_address,
    dhcp_end_address    => $dhcp_end_address,
    dhcp_netmask        => $dhcp_netmask,
    dhcp_gateway        => $dhcp_gateway,
    dhcp_interface      => $dhcp_interface,

    cobbler_user        => $cobbler_user,
    cobbler_password    => $cobbler_password ,

    pxetimeout          => $pxetimeout,
  }


  # CentOS distribution
  # Uncomment the following section if you want CentOS image to be downloaded and imported into Cobbler
  # Replace "http://address/of" with valid hostname and path to the mirror where the image is stored

  /*
  Class[cobbler::distro::centos63_x86_64] ->
  Class[cobbler::profile::centos63_x86_64]

  class { cobbler::distro::centos63_x86_64:
    http_iso => "http://address/of/CentOS-6.3-x86_64-minimal.iso",
    ks_url   => "cobbler",
    require  => Class[cobbler],
  }

  class { cobbler::profile::centos63_x86_64: }
  */


  # Ubuntu distribution
  # Uncomment the following section if you want Ubuntu image to be downloaded and imported into Cobbler
  # Replace "http://address/of" with valid hostname and path to the mirror where the image is stored  

  /*
  Class[cobbler::distro::ubuntu_1204_x86_64] ->
  Class[cobbler::profile::ubuntu_1204_x86_64]

  class { cobbler::distro::ubuntu_1204_x86_64 :
    http_iso => "http://address/of/ubuntu-12.04-x86_64-mini.iso",
    require  => Class[cobbler],
  }

  class { cobbler::profile::ubuntu_1204_x86_64 : }
  */


  # RHEL distribution
  # Uncomment the following section if you want RHEL image to be downloaded and imported into Cobbler
  # Replace "http://address/of" with valid hostname and path to the mirror where the image is stored

  /*
  Class[cobbler::distro::rhel63_x86_64] ->
  Class[cobbler::profile::rhel63_x86_64]
  
  class { cobbler::distro::rhel63_x86_64:
    http_iso => "http://address/of/rhel-server-6.3-x86_64-boot.iso",
    ks_url   => "http://address/of/rhel/base/mirror/6.3/os/x86_64",
    require  => Class[cobbler],
  }
  class { cobbler::profile::rhel63_x86_64: }
  */
  
  class { cobbler::checksum_bootpc: }

  # IT IS NEEDED IN ORDER TO USE cobbler_system.py SCRIPT
  # WHICH USES argparse PYTHON MODULE
  package {"python-argparse": }

}
