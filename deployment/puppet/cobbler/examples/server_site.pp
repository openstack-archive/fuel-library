#
# This manifest file is being used in automated internal tests in Mirantis network.
# It references internal repositories with packages.
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
$mirror_type         = 'default'

stage { 'openstack-custom-repo': before => Stage['main'] }
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo', type=>$mirror_type }

node fuel-cobbler {
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

  Class[cobbler::server] ->
    Class[cobbler::distro::centos63_x86_64]

    # class { cobbler::distro::centos63_x86_64:
    #   http_iso => "http://10.100.0.1/iso/CentOS-6.3-x86_64-netinstall.iso",
    #   ks_url   => "http://172.18.8.52/~hex/centos/6.3/os/x86_64",
    # }

    class { cobbler::distro::centos63_x86_64:
      http_iso => "http://172.18.67.168/CentOS-6.3-x86_64-minimal.iso",
      ks_url   => "http://172.18.67.168/centos-repo/centos-6.3",
    }


    Class[cobbler::distro::centos63_x86_64] ->
    Class[cobbler::profile::centos63_x86_64]

    class { cobbler::profile::centos63_x86_64:
      ks_repo => [
        {
        "name" => "Puppet",
        "url"  => "http://yum.puppetlabs.com/el/6/products/x86_64",
        },
        {
        "name" => "PuppetDeps",
        "url"  => "http://yum.puppetlabs.com/el/6/dependencies/x86_64",
        },
        {
        "name" => "Centos-archive-base",
        "url"  => "http://172.18.67.168/centos-repo/centos-6.3",
        },
        {
        "name" => "Epel",
        "url"  => "http://172.18.67.168/centos-repo/epel",
        }
      ]
    }

    # UBUNTU distribution
      Class[cobbler::distro::ubuntu_1204_x86_64] ->
      Class[cobbler::profile::ubuntu_1204_x86_64]

      class { cobbler::distro::ubuntu_1204_x86_64 :
        http_iso => "http://172.18.67.168/mini.iso",
        require  => Class[cobbler],
        ks_url   => "http://172.18.67.168/ubuntu-repo/mirror.yandex.ru/ubuntu",
      }

      class { cobbler::profile::ubuntu_1204_x86_64 :
          ks_repo => [
          {
            "name" => "Puppet",
            "url"  => "http://apt.puppetlabs.com/",
            "release" => "precise",
            "repos" => "main dependencies",
          },
          {
            "name" => "Canonical",
            "url"  => "http://172.18.67.168/ubuntu-cloud.archive.canonical.com/ubuntu/",
            "release" => "precise-updates/folsom",
            "repos" => "main",
          },
        ],
      }

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
