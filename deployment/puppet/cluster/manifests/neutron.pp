# not a doc string

class cluster::neutron () {

  Package['pacemaker'] ->
  File<| title == 'ocf-mirantis-path' |> ->
  Package['neutron'] ->

  file {'q-agent-cleanup.py':
    path   => '/usr/bin/q-agent-cleanup.py',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/neutron/q-agent-cleanup.py",
  } ->

  file {'neutron-root':
    path => '/etc/sudoers.d/neutron-root',
    mode => '0440',
    owner => root,
    group => root,
    source => "puppet:///modules/neutron/neutron-root",
  } ->

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