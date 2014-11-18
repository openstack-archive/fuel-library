#
class osnailyfacter::patching_classes(
  $ensure = latest,
  $tag    = 'openstack-dependency',
) {
  case $::osfamily {
    'Debian': {
      $packages={
        'murano-apps' => {},
        'ieee-data' => {},
        'python-openstack-auth' => {},
        'python-memcache' => {},
        'python-netaddr' => {},
      }
    }
    'RedHat': {
      $packages={
        'murano-apps' => {},
        'python-django-openstack-auth' => {},
        'python-memcached' => {},
        'python-six' => {},
        'python-sqlalchemy' => {},
      }
    }
  }

  $defaults = {
    'ensure'   => $ensure,
    'tag'      => $tag,
  }
  create_resources('osnailyfacter::dependency_package', $packages, $defaults )

  notify{'Installing or updating explicit OpenStack dependencies':} ->
  Dependency_package <| tag == $tag |> ->
  notify{'Finished install or update explicit OpenStack dependencies': }
  #TODO (bogdando) notify Openstack service on updates
}
