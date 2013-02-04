# == Class: l23network::l2
#
# Module for configuring L2 network.
# Requirements, packages and services.
#
class l23network::l2 {
  case $::osfamily {
    /(?i)(debian)/: {
      $service_name = 'openvswitch-switch'
      $status_cmd   = '/etc/init.d/openvswitch-switch status'
      $ovs_packages = ['openvswitch-datapath-dkms', 'openvswitch-switch']
    }
    /(?i)(redhat)/: {
      $service_name = 'openvswitch' #'ovs-vswitchd'
      $status_cmd   = '/etc/init.d/openvswitch status'
      $ovs_packages = ['kmod-openvswitch', 'openvswitch']
    }
    /(?i)linux/: {
      case $::operatingsystem {
        /(?i)archlinux/: {
          $service_name = 'openvswitch.service'
          $status_cmd   = 'systemctl status openvswitch'
          $ovs_packages = ['aur/openvswitch']
        }
        default: {
          fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
        }
      }
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
  package {$ovs_packages:
    ensure  => present,
    before  => Service['openvswitch-service'],
  }
  service {'openvswitch-service':
    ensure    => running,
    name      => $service_name,
    enable    => true,
    hasstatus => true,
    status    => $status_cmd,
  }
}
