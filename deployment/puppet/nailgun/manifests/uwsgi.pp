# == Class: nailgun::uwsgi
#
#
#
# === Parameters
#
class nailgun::uwsgi(
) {

  if $::physicalprocessorcount > 8  {
    $physicalprocessorcount = 8
  } else {
    $physicalprocessorcount = $::physicalprocessorcount
  }

  package { ['uwsgi', 'uwsgi-plugin-common', 'uwsgi-plugin-python']:
    ensure => installed,
  }

  file { '/etc/nailgun/uwsgi_nailgun.yaml':
    content => template('nailgun/uwsgi_nailgun.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['uwsgi'],
  }

  file { '/usr/bin/nailgun-uwsgi':
    ensure => present,
  }

  Class[Nailgun::Venv]->
    File['/etc/nailgun/uwsgi_nailgun.yaml']

  Class[Nailgun::Venv]->
    File['/usr/bin/nailgun-uwsgi']
}
