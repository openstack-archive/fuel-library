$server              = '10.0.0.100'
$domain_name         = 'mirantis.com'
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

case $::osfamily {
  'Debian': {
#    class { 'openstack::repo::apt':
#      key => '420851BC',
#      location => 'http://172.18.66.213/deb',
#      key_source => 'http://172.18.66.213/gpg.pub',
#      origin => '172.18.66.213',
#      stage => 'openstack-custom-repo'
#    }
  }
  'RedHat': {
#    class { 'openstack::repo::yum':
#      repo_name  => 'openstack-epel-fuel',
#      location   => 'http://download.mirantis.com/epel-fuel',
#      key_source => 'https://fedoraproject.org/static/0608B895.txt',
#      stage      => 'openstack-custom-repo',
#    }
  }
  default: {
    fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
  }
}

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
    #  Class[cobbler::server] ->
    # Class[cobbler::distro::centos63_x86_64]
    #
    # class { cobbler::distro::centos63_x86_64:
    #  http_iso => "http://172.18.67.168/CentOS-6.3-x86_64-minimal.iso",
    #  ks_url   => "cobbler",
    # }

    # Class[cobbler::distro::centos63_x86_64] ->
    # Class[cobbler::profile::centos63_x86_64]

    # class { cobbler::profile::centos63_x86_64: }

    # UBUNTU distribution
    #  Class[cobbler::distro::ubuntu_1204_x86_64] ->
    #  Class[cobbler::profile::ubuntu_1204_x86_64]
    #
    #  class { cobbler::distro::ubuntu_1204_x86_64 :
    #    http_iso => "http://172.18.67.168/mini.iso",
    #    require  => Class[cobbler],
    #  }
    #
    #  class { cobbler::profile::ubuntu_1204_x86_64 : }

    # RHEL distribution
    # class { cobbler::distro::rhel63_x86_64:
    #   http_iso => "http://address/of/rhel-server-6.3-x86_64-boot.iso",
    #   ks_url   => "http://address/of/rhel/base/mirror/6.3/os/x86_64",
    # }
    #
    # Class[cobbler::distro::rhel63_x86_64] ->
    # Class[cobbler::profile::rhel63_x86_64]
    #
    # class { cobbler::profile::rhel63_x86_64: }

    class { cobbler::checksum_bootpc: }

    # IT IS NEEDED IN ORDER TO USE cobbler_system.py SCRIPT
    # WHICH USES argparse PYTHON MODULE
    package {"python-argparse": }
}
