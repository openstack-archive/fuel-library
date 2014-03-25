# == Class: nailgun::uwsgi
#
#
#
# === Parameters
#
class nailgun::uwsgi(
) {

  if $::physicalprocessorcount <= 8 {
    $physicalprocessorcount = ($::physicalprocessorcount - 1)
  } else {
    $physicalprocessorcount = 8
  }

  package { 'uwsgi':
    ensure => installed,
  }

  file { '/etc/nailgun/uwsgi_nailgun.yaml':
    content => template('nailgun/uwsgi_nailgun.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['uwsgi'],
  }

  Class[Nailgun::Venv]->
    File['/etc/nailgun/uwsgi_nailgun.yaml']
}
