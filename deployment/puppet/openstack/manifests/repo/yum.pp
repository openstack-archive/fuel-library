class openstack::repo::yum (
  $repo_name,
  $location,
  $key_source,
  $include_src = false,
  $priority = 1,
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
    gpgcheck => 1,
    gpgkey   => $key_source,
    priority => $priority,
    enabled  => 1,
  }
}
