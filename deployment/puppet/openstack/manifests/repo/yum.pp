class openstack::repo::yum (
  $repo_name,
  $location = absent,
  $key_source,
  $include_src = false,
  $priority = 1,
  $mirrorlist = absent
)
  {

  if defined(Package['yum-plugin-priorities']) {}
  else {
    package { 'yum-plugin-priorities':
      ensure => present,
    }
  }

  Package['yum-plugin-priorities'] -> Yumrepo[$repo_name]

  yumrepo {$repo_name:
    baseurl  => $location,
    mirrorlist => $mirrorlist,
    gpgcheck => 1,
    gpgkey   => $key_source,
    priority => $priority,
    enabled  => 1,
    descr => $repo_name,
  }
    yumrepo {'puppetlabs-products': enabled=>0 } 
    yumrepo {'puppetlabs-deps': enabled=>0} 
  }
