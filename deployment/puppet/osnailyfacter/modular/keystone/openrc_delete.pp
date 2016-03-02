notice('MODULAR: openrc_delete.pp')

file { '/root/openrc':
  ensure => absent,
}
