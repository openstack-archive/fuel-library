class ovs {
  case $::osfamily {
    /(?i)(debian|ubuntu)/: {
      $service_name = 'openvswitch-switch'
      $status_cmd   = '/etc/init.d/openvswitch-switch status'
      $ovs_packages = ["openvswitch-datapath-dkms", "openvswitch-switch"]
    }
    /(?i)(centos|redhat)/: {
      $service_name = 'openvswitch' #'ovs-vswitchd'
      $status_cmd   = '/etc/init.d/openvswitch status'
      $ovs_packages = ["kmod-openvswitch", "openvswitch"]
    }
    /(?i)linux/: {
      case $::operatingsystem {
        /(?i)archlinux/: {
          $service_name = 'openvswitch.service'
          $status_cmd   = 'systemctl status openvswitch'
          $ovs_packages = ["aur/openvswitch"]
        }
      }
    }
  }
  package {$ovs_packages:
        ensure  => present,
        before  => Service['openvswitch-service'],
  }
  service {'openvswitch-service':
    name        => $service_name,
    ensure      => true,
    enable      => true,
    hasstatus   => true,
    status      => $status_cmd,
  }
}
