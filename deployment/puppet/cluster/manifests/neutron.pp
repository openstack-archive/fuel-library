# not a doc string

class cluster::neutron () {

  Package['pacemaker'] ->
  File<| title == 'ocf-mirantis-path' |> ->
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
