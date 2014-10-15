# Refreshes the yum database after adding repositories and
# before installing packages.
class openstack_extras::repo::yum_refresh {
  exec { 'yum_refresh':
    command     => '/usr/bin/yum clean all',
    refreshonly => true,
  }
  Exec['yum_refresh'] -> Package<||>
}
