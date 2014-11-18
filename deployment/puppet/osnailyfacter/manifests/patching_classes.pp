class osnailyfacter::patching_classes() {
  case $::osfamily {
    'Debian': {
      $packages=[
        'murano-apps',
        'ieee-data',
        'python-openstack-auth',
        'python-memcache',
        'python-netaddr'
      ]
    }
    'RedHat': {
      $packages=[
        'murano-apps',
        'python-django-openstack-auth',
        'python-memcached',
        'python-six',
        'python-sqlalchemy'
      ]
    }
  }
  notify{'Installing explicit OpenStack dependencies':} ->
  package {$packages: ensure => latest }
}
