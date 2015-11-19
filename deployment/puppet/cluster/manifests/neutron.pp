# not a doc string

class cluster::neutron () {

  Package['neutron']  ->

  file {'/var/cache/neutron':
    ensure  => directory,
    path   => '/var/cache/neutron',
    mode   => '0755',
    owner  => neutron,
    group  => neutron,
  }

  if !defined(Package['lsof']) {
    package { 'lsof': }
  }
}
