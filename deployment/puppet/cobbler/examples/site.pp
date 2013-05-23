#
# This manifest file is being used in automated
# internal tests in Mirantis network.
# It references internal repositories with packages.
#

# Fast mirror for your location, it will be used to download packages
$fast_mirror         = 'http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu'

# [server] IP address that will be used as address of cobbler server.
# It is needed to download kickstart files, call cobbler API and
# so on. Required.
$server              = '10.0.0.100'

# Interface for cobbler instances
$dhcp_interface      = 'eth1'

# Network parameters for DHCP to use for bare metal deployment on management network.

# [domain_name] Domain name that will be used as default for
# installed nodes. Required.
# [name_server] DNS ip address to be used by installed nodes
# [next_server] IP address that will be used as PXE tftp server. Required.
# [dhcp_start_address] First address of dhcp range
# [dhcp_end_address] Last address of dhcp range
# [dhcp_netmask] Netmask of the network
# [dhcp_gateway] Gateway address for installed nodes
# [dhcp_interface] Interface where to bind dhcp and tftp services
# [pxetimeout] Pxelinux will wail this count of 1/10 seconds before
# use default pxe item. To disable it use 0. Required.
# [cobbler_user] Cobbler web interface username
# [cobbler_password] Cobbler web interface password

$dhcp_start_address  = '10.0.0.201'
$dhcp_end_address    = '10.0.0.250'
$dhcp_netmask        = '255.255.255.0'
$dhcp_gateway        = '10.0.0.100'
$domain_name         = 'localdomain'
$name_server         = '10.0.0.100'
$next_server         = '10.0.0.100'
$cobbler_user        = 'cobbler'
$cobbler_password    = 'cobbler'
$pxetimeout          = '0'

# Predefined mirror type to use: internal or external (should be removed soon)
$mirror_type         = 'default'

# Management network to set up NAT masquerade in iptables on cobbler/puppetmaster node
# (should be automatically calculated from DHCP parameters defined above)
$nat_range           = '10.0.0.0/24'

#----Don't edit anything below this line----------------------------------

stage { 'openstack-custom-repo': before => Stage['main'] }
class { 'openstack::mirantis_repos':
  stage => 'openstack-custom-repo',
  type  => $mirror_type,
}

node fuel-cobbler {

  class {'cobbler::nat': nat_range => $nat_range}

  class { 'cobbler':
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

  Class['cobbler::server'] ->
    Class['cobbler::distro::centos64_x86_64']

    # class { 'cobbler::distro::centos63_x86_64':
    #   http_iso => 'http://10.100.0.1/iso/CentOS-6.3-x86_64-netinstall.iso',
    #   ks_url   => 'http://172.18.8.52/~hex/centos/6.3/os/x86_64',
    # }

    class { 'cobbler::distro::centos64_x86_64':
      http_iso => 'http://download.mirantis.com/epel-fuel-folsom-2.1/CentOS-6.4-x86_64-minimal.iso',
      ks_url   => 'cobbler',
    }


    Class['cobbler::distro::centos64_x86_64'] ->
    Class['cobbler::profile::centos64_x86_64']

    class { 'cobbler::profile::centos64_x86_64' : }

    # UBUNTU distribution
      Class['cobbler::distro::ubuntu_1204_x86_64'] ->
      Class['cobbler::profile::ubuntu_1204_x86_64']

      class { 'cobbler::distro::ubuntu_1204_x86_64' :
        http_iso => 'http://172.18.67.168/mini.iso',
        require  => Class[cobbler],
        ks_url   => $fast_mirror,
      }

      class { 'cobbler::profile::ubuntu_1204_x86_64' :
          ks_repo => [
          {
            'name'    => 'Puppet',
            'url'     => 'http://apt.puppetlabs.com/',
            'release' => 'precise',
            'repos'   => 'main dependencies',
          },
        ],
      }

    # RHEL distribution
    # class { 'cobbler::distro::rhel63_x86_64':
    #   http_iso => 'http://address/of/rhel-server-6.3-x86_64-boot.iso',
    #   ks_url   => 'http://address/of/rhel/base/mirror/6.3/os/x86_64',
    # }
    #
    # Class['cobbler::distro::rhel63_x86_64'] ->
    # Class['cobbler::profile::rhel63_x86_64']
    #
    # class { 'cobbler::profile::rhel63_x86_64': }

    class { 'cobbler::checksum_bootpc': }

    # IT IS NEEDED IN ORDER TO USE cobbler_system.py SCRIPT
    # WHICH USES argparse PYTHON MODULE
    package {'python-argparse': }
}
