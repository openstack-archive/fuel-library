class cobbler::distro::centos63-x86_64(
  $centos_http_iso = "http://mirror.stanford.edu/yum/pub/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-netinstall.iso"
  ) {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}
  
  file { "/var/www/cobbler/ks_mirror/CentOS-6.3-x86_64":
    ensure => directory,
    owner => root,
    group => root,
    mode => 0555,
  }

  # HERE IS ASSUMED THAT wget PACKAGE INSTALLED AS WE NEED IT
  # TO DOWNLOAD CENTOS NETINSTALL ISO IMAGE

  $centos_iso = "/var/www/cobbler/ks_mirror/CentOS-6.3-x86_64-netinstall.iso"
  exec { "${centos_iso}":
    command => "wget -q -O- ${centos_http_iso} > ${centos_iso}",
    onlyif => "test ! -e ${centos_iso}"
  }

  mount { "/var/www/cobbler/ks_mirror/CentOS-6.3-x86_64":
    device => "/var/www/cobbler/ks_mirror/CentOS-6.3-x86_64-netinstall.iso",
    options => "loop",
    fstype => "iso9660",
    ensure => mounted,
    require => [Exec["${centos_iso}"], File["/var/www/cobbler/ks_mirror/CentOS-6.3-x86_64"]],
  }

  cobbler_distro { "centos63-x86_64":
    kernel => "/var/www/cobbler/ks_mirror/CentOS-6.3-x86_64/isolinux/vmlinuz",
    initrd => "/var/www/cobbler/ks_mirror/CentOS-6.3-x86_64/isolinux/initrd.img",
    arch => "x86_64",
    breed => "redhat",
    osversion => "rhel6",
    require => Mount["/var/www/cobbler/ks_mirror/CentOS-6.3-x86_64"],
  }
}
