class openstack::repo::apt (
  $location,
  $key,
  $key_source,
  $origin,
  $include_src = false,
  $priority = 1001,
) {
  apt::source { 'openstack-apt-repo':
    location => $location,
    key => $key,
    key_source => $key_source,
    include_src => $include_src,
  }

  apt::pin { 'openstack-apt-repo':
    priority => 1001,
    origin => $origin,
    require => Apt::Source['openstack-apt-repo'],
  }
}
