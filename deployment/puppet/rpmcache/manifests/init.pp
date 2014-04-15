class rpmcache::rpmcache ( $releasever, $pkgdir, $numtries,
$rh_username, $rh_password, $rh_base_channels, $rh_openstack_channel,
$use_satellite = false, $sat_hostname = "", $activation_key = "",
$sat_base_channels, $sat_openstack_channel, $numtries = 10)  {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}
  $redhat_management_type = $use_satellite ? {
    "true"              => "site",
    "false"             => "cert",
    default             => "cert",
  }

  $redhat_management_key = $activation_key ? {
    /[[:alnum:]]/       => "redhat_management_key=$activation_key",
    default             => undef,
  }

  $redhat_management_server = $sat_hostname ? {
    /[[:alnum:]]/       => "redhat_management_server=$sat_hostname",
    default             => undef,
  }


  package { "yum-utils":
    ensure => "installed"
  } ->
  package { "subscription-manager":
    ensure => "installed"
  } ->

  file { '/etc/pki/product':
    ensure => directory,
  } ->

  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release':
    ensure => present,
    source => 'puppet:///modules/rpmcache/RPM-GPG-KEY-redhat-release',
    owner => 'root',
    group => 'root',
    mode => 0644,
  } ->

  exec { 'rpm-import-rh-gpg-key':
    command => 'rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release',
    require => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release'],
    logoutput => true
  } ->

  file { '/etc/nailgun/':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755'
  } ->
  file { '/etc/nailgun/required-rpms.txt':
    ensure => present,
    source => 'puppet:///modules/rpmcache/required-rpms.txt',
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File['/etc/nailgun/']
  } ->

  file { '/usr/local/bin':
    ensure => directory,
  } ->
  file { '/usr/local/bin/repotrack':
    ensure => present,
    source => 'puppet:///modules/rpmcache/repotrack',
    owner => 'root',
    group => 'root',
    mode => 0755,
  } ->

  file { '/usr/sbin/build_rpm_cache':
    content => template('rpmcache/build_rpm_cache.erb'),
    owner => 'root',
    group => 'root',
    mode => 0755,
  } ->
  exec { 'build_rpm_cache':
    command => '/usr/sbin/build_rpm_cache',
    require => File['/usr/sbin/build_rpm_cache'],
    logoutput => true,
    timeout => 0
  } ->
  cobbler_distro { "rhel-x86_64":
    kernel => "${pkgdir}/isolinux/vmlinuz",
    initrd => "${pkgdir}/isolinux/initrd.img",
    arch => "x86_64",
    breed => "redhat",
    osversion => "rhel6",
    ksmeta => "tree=http://@@server@@:8080/rhel/6.4/nailgun/x86_64/",
  } ->

  cobbler_profile { "rhel-x86_64":
    kickstart => "/var/lib/cobbler/kickstarts/centos-x86_64.ks",
    kopts => "biosdevname=0",
    distro => "rhel-x86_64",
    ksmeta => "redhat_register_user=${rh_username} redhat_register_password=${rh_password} redhat_management_type=$redhat_management_type $redhat_management_server $redhat_management_key",
    menu => true,
    require => Cobbler_distro["rhel-x86_64"],
  } ->
  exec {'rebuild-fuel-repo':
    command => "/bin/cp -f /var/www/nailgun/centos/fuelweb/x86_64/repodata/comps.xml ${pkgdir}/repodata/comps.xml; /usr/bin/createrepo --simple-md-filenames -g ${pkgdir}/repodata/comps.xml ${pkgdir}",
  }

  file { '/etc/nailgun/req-fuel-rhel.txt':
    ensure => present,
    source => 'puppet:///modules/rpmcache/req-fuel-rhel.txt',
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File['/etc/nailgun/']
  } ->
  exec {'fuel-rpms':
    command => "/bin/mkdir -p ${pkgdir}/fuel/Packages; rsync -ra --include-from=/etc/nailgun/req-fuel-rhel.txt /var/www/nailgun/centos/fuelweb/x86_64/Packages/. ${pkgdir}/fuel/Packages/.",
    logoutput => true,
    before    => Exec['rebuild-fuel-repo'],
  }
}
