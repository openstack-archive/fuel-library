class provision::tftp (
  $bootstrap_kernel_params = $::provision::params::bootstrap_kernel_params,
  $bootstrap_kernel_path   = $::provision::params::bootstrap_kernel_path,
  $bootstrap_initrd_path   = $::provision::params::bootstrap_initrd_path,
  $bootstrap_menu_label    = $::provision::params::bootstrap_menu_label,
  $tftp_root               = $::provision::params::tftp_root,
  $chain32_files           = [],
) inherits provision::params {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  case $::osfamily {
    'RedHat': {
      $tftp_packages = ['xinetd', 'tftp-server', 'syslinux']

      service { 'xinetd':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        require    => Package[$tftp_packages],
      }

      file { '/etc/xinetd.conf':
        content => template('provision/xinetd.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        require => Package[$tftp_packages],
        notify  => Service['xinetd'],
      }

      file { '/etc/xinetd.d/tftp' :
        content => template('provision/tftp.xinetd.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package[$tftp_packages],
        notify  => Service['xinetd'],
      }

    }
    default : {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }

  ensure_packages($tftp_packages)

  file { ["${tftp_root}/images", "${tftp_root}/pxelinux.cfg"] :
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755',
    require => Package[$tftp_packages],
  }

  file { "${tftp_root}/pxelinux.cfg/default" :
    ensure => present,
    content => template("provision/tftp.default.erb"),
    owner => 'root',
    group => 'root',
    mode => '0644',
    require => File["${tftp_root}/pxelinux.cfg"],
  }

  file { "${tftp_root}/chain.c32":
    source => '/usr/share/syslinux/chain.c32',
    require => Package[$tftp_packages],
  }

  file { "${tftp_root}/pxelinux.0":
    source => '/usr/share/syslinux/pxelinux.0',
    require => Package[$tftp_packages],
  }

  file { "${tftp_root}/menu.c32":
    source => '/usr/share/syslinux/menu.c32',
    require => Package[$tftp_packages],
  }

  # TODO Create custom type that will remove all 01-* files that
  # are not in the $chain32_files list
  exec { "remove ${tftp_root}/pxelinux.cfg/01-* files" :
    command => "find ${tftp_root}/pxelinux.cfg -type f -name '01-*' -delete",
    require => File["${tftp_root}/pxelinux.cfg"],
  } ->

  file { $chain32_files :
    ensure => present,
    content => template("provision/tftp.chain32.erb"),
    owner => 'root',
    group => 'root',
    mode => '0644',
    require => File["${tftp_root}/pxelinux.cfg"],
  }
}
