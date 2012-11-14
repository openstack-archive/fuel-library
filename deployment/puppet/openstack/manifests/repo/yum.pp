class openstack::repo::yum (
  $repo_name,
  $location = absent,
  $key_source,
  $failovermethod = absent,
  $include_src = false,
  $priority = 1,
  $gpgcheck = 1,
  $mirrorlist = absent,
  $descr = $repo_name,
  $rhel_location = undef,
)
  {

  #if defined(Package['yum-plugin-priorities']) {}
  #else {
  #  package { 'yum-plugin-priorities':
  #    ensure => present,
  #  }
  #}

  #Package['yum-plugin-priorities'] -> Yumrepo[$repo_name]

  yumrepo {$repo_name:
    baseurl        => $location,
    mirrorlist     => $mirrorlist,
    failovermethod => $failovermethod,
    gpgcheck       => $gpgcheck,
    gpgkey         => $key_source,
    priority       => $priority,
    enabled        => 1,
    descr          => $descr,
  }
  if ($rhel_location) {
    yumrepo {'rhel-local':
      baseurl  => $rhel_location,
      gpgcheck => 0,
      enabled  => 1,
    }
  }
    if defined (Yumrepo['puppetlabs-products']) {yumrepo {'puppetlabs-products': enabled=>0 }}
    if defined (Yumrepo['puppetlabs-deps']) {yumrepo {'puppetlabs-deps': enabled=>0}}
  }
