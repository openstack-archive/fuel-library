class vswitch::ovs(
  $package_ensure = 'present'
) {
  case $::osfamily {
    Debian: {
      $kernel_headers = "linux-headers-${::kernelrelease}"

      if ! defined(Package[$kernel_headers]) {
        package { $kernel_headers: ensure => present }
      }

      package {["openvswitch-switch", "openvswitch-datapath-dkms"]:
        ensure  => $package_ensure,
        require => Package[$kernel_headers],
        before  => Service['openvswitch-switch'],
      }

      $openvswitch_service = 'openvswitch-switch'
    }

    RedHat: {
      # $kernel_headers = "linux-headers-${::kernelrelease}"

      # ensure_resource(
      #   'package',
      #   $kernel_headers,
      #   {'ensure' => 'present' }
      # )
      package {["openvswitch", "kmod-openvswitch"]:
        ensure  => $package_ensure,
        # require => Package[$kernel_headers],
        before  => Service['openvswitch-switch'],
      }


      $openvswitch_service = 'openvswitch'
    }
  }

  service {"openvswitch-switch":
    name        => $openvswitch_service,
    ensure      => true,
    enable      => true,
    hasstatus   => true,
    status      => "/etc/init.d/openvswitch-switch status",
  }
}
