class cobbler::distro::centos63-x86_64(
  $http_iso = "http://mirror.stanford.edu/yum/pub/centos/6.3/isos/x86_64/CentOS-6.3-x86_64-netinstall.iso",
  $ks_url = "http://mirror.stanford.edu/yum/pub/centos/6.3/os/x86_64"
  ) {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  $ks_mirror = '/var/www/cobbler/ks_mirror'

  # CentOS-6.3-x86_64-netinstall
  $iso_name = extension_basename($http_iso, "true")
  # CentOS-6.3-x86_64-netinstall.iso
  $iso_basename = extension_basename($http_iso) 
  # /var/www/cobbler/ks_mirror/CentOS-6.3-x86_64-netinstall.iso
  $iso = "${ks_mirror}/${iso_basename}"
  # /var/www/cobbler/ks_mirror/CentOS-6.3-x86_64-netinstall
  $iso_mnt = "${ks_mirror}/${iso_name}"
  # /var/www/cobbler/links/CentOS-6.3-x86_64-netinstall
  $iso_link = "/var/www/cobbler/links/$iso_name"

  if $ks_url == "cobbler" {
    $tree = "http://@@server@@/cblr/links/${iso_name}"
  }
  else {
    $tree = $ks_url
  }
  
  file { $iso_mnt:
    ensure => directory,
    owner => root,
    group => root,
    mode => 0555,
  }

  # HERE IS ASSUMED THAT wget PACKAGE INSTALLED AS WE NEED IT
  # TO DOWNLOAD CENTOS NETINSTALL ISO IMAGE

  exec { "wget ${http_iso}":
    command => "wget -q -O- ${http_iso} > ${iso}",
    onlyif => "test ! -e ${iso}"
  }

  mount { $iso_mnt:
    device => $iso,
    options => "loop",
    fstype => "iso9660",
    ensure => mounted,
    require => [Exec["wget ${http_iso}"], File[$iso_mnt]],
  }

  file { $iso_link:
    ensure => link,
    target => $iso_mnt,
  }

  
  cobbler_distro { "centos63-x86_64":
    kernel => "${iso_mnt}/isolinux/vmlinuz",
    initrd => "${iso_mnt}/isolinux/initrd.img",
    arch => "x86_64",
    breed => "redhat",
    osversion => "rhel6",
    ksmeta => "tree=${tree}",
    require => Mount[$iso_mnt],
  }
}
