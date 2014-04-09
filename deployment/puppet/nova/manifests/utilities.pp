# == Class nova::utilities
#
# Extra packages used by nova tools
# unzip swig screen parted curl euca2ools libguestfs-tools - extra packages
class nova::utilities {
  if $::osfamily == 'Debian' {
    ensure_packages(['unzip', 'screen', 'parted', 'curl', 'euca2ools'])

    package {'libguestfs-tools':
      ensure       => present,
      responsefile => '/var/run/guestfs.seed',
      require      => File['guestfs.seed']
    }

    file {'guestfs.seed':
      ensure       => present,
      path         => '/var/run/guestfs.seed',
      content      => 'libguestfs0 libguestfs/update-appliance boolean true'
    }
  }
}
