#
# This file does not seem to be used anywhere. Consider for deletion, or replace this comment with the actual usage description.
#

node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  exec { "enable_forwarding":
    command => "echo 1 > /proc/sys/net/ipv4/ip_forward",
    unless => "cat /proc/sys/net/ipv4/ip_forward | grep -q 1",
  }

  case $operatingsystem {
    /(?i)(centos|redhat)/: {
      exec { "enable_nat_all":
        command => "iptables -t nat -I POSTROUTING 1 -s 10.100.0.0/24 ! -d 10.100.0.0/24 -j MASQUERADE; \
        /etc/init.d/iptables save",
        unless => "iptables -t nat -S POSTROUTING | grep -q \"^-A POSTROUTING -s 10.100.0.0/24 ! -d 10.100.0.0/24 -j MASQUERADE\""
      }

      exec { "enable_nat_filter":
        command => "iptables -t filter -I FORWARD 1 -j ACCEPT; \
        /etc/init.d/iptables save",
        unless => "iptables -t filter -S FORWARD | grep -q \"^-A FORWARD -j ACCEPT\""
      }

      exec { "save_ipv4_forward":
        command => "sed -i --follow-symlinks -e \"/net\.ipv4\.ip_forward/d\" /etc/sysctl.conf && echo \"net.ipv4.ip_forward = 1\" >> /etc/sysctl.conf",
        unless => "grep -q \"^\s*net\.ipv4\.ip_forward = 1\" /etc/sysctl.conf",
      }
    }
    /(?i)(debian|ubuntu)/: {
      # In order to save these rules and to make them raising on boot you supposed to
      # define to resources File["/etc/network/if-post-down.d/iptablessave"]
      # and File["/etc/network/if-pre-up.d/iptablesload"]. Those two resources already
      # defined in cobbler::iptables class, so if you use default init.pp file
      # you already have those files defined

      exec { "enable_nat_all":
        command => "iptables -t nat -I POSTROUTING 1 -s 10.100.0.0/24 ! -d 10.100.0.0/24 -j MASQUERADE; \
        iptables-save -c > /etc/iptables.rules",
        unless => "iptables -t nat -S POSTROUTING | grep -q \"^-A POSTROUTING -s 10.100.0.0/24 ! -d 10.100.0.0/24 -j MASQUERADE\""
      }

      exec { "enable_nat_filter":
        command => "iptables -t filter -I FORWARD 1 -j ACCEPT; \
        iptables-save -c > /etc/iptables.rules",
        unless => "iptables -t filter -S FORWARD | grep -q \"^-A FORWARD -j ACCEPT\""
      }

      # it is for the sake of raising up forwarding mode on boot
      file { "/etc/sysctl.d/60-ipv4_forward.conf" :
        content => "net.ipv4.ip_forward = 1",
        owner => root,
        group => root,
        mode => 0644,
      }
    }
  }

  class { cobbler :
    server              => '10.100.0.201',

    domain_name         => 'localdomain',
    name_server         => '10.100.0.201',
    next_server         => '10.100.0.201',

    dhcp_start_address  => '10.100.0.221',
    dhcp_end_address    => '10.100.0.254',
    dhcp_netmask        => '255.255.255.0',
    dhcp_gateway        => '10.100.0.1',
    dhcp_interface      => 'eth0',

    cobbler_user        => 'cobbler',
    cobbler_password    => 'cobbler',

    pxetimeout          => '0'
  }

  # CENTOS distribution
  Class[cobbler::distro::centos64_x86_64] ->
  Class[cobbler::profile::centos64_x86_64]

  class { cobbler::distro::centos64_x86_64 :
    http_iso => "http://10.100.0.1/iso/CentOS-6.4-x86_64-minimal.iso",
    ks_url   => "cobbler",
    require  => Class[cobbler],
  }

  class { cobbler::profile::centos64_x86_64 :
    ks_repo => [{
                "name" => "Local",
                "url" => "http://10.100.0.1:1234/centos/6.4/os/x86_64"
                }],
  }


  # UBUNTU distribution
  Class[cobbler::distro::ubuntu_1204_x86_64] ->
  Class[cobbler::profile::ubuntu_1204_x86_64]

  class { cobbler::distro::ubuntu_1204_x86_64 :
    http_iso => "http://10.100.0.1/iso/ubuntu-12.04-x86_64-mini.iso",
    ks_url   => "http://10.100.0.1:1234/ubuntu"
  }

  class { cobbler::profile::ubuntu_1204_x86_64 :
    ks_repo => [{
        "name" => "Local",
        "url"  => "http://10.100.0.1:1234/ubuntu",
        "release" => "precise",
        "repos" => "main",
      },
      {
        "name" => "Puppet",
        "url"  => "http://apt.puppetlabs.com/",
        "release" => "precise",
        "repos" => "main dependencies",
      },
    ],
  }

  class { cobbler::checksum_bootpc: }

}
