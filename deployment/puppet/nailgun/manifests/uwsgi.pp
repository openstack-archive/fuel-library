# == Class: nailgun::uwsgi
#
#
#
# === Parameters
#
class nailgun::uwsgi(
  $production,
) {

  if $::physicalprocessorcount > 4  {
    $physicalprocessorcount = 8
  } else {
    $physicalprocessorcount = $::physicalprocessorcount * 2
  }

  if $production == "docker-build" {
    $somaxconn = "100"
  } else {
    #Increase max connections for sockets for Nailgun uWSGI
    $somaxconn = "4096"
    sysctl::value{'net.core.somaxconn': value => $somaxconn}
  }

  package { ['uwsgi', 'uwsgi-plugin-common', 'uwsgi-plugin-python']:
    ensure => installed,
  }

  file { '/etc/nailgun/uwsgi_nailgun.yaml':
    content => template('nailgun/uwsgi_nailgun.yaml.erb'),
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['uwsgi'],
  }

  file { '/var/lib/nailgun-uwsgi':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
  Class[Nailgun::Venv]->
    File['/etc/nailgun/uwsgi_nailgun.yaml']

  Class[Nailgun::Venv]->
    File['/var/lib/nailgun-uwsgi']
}
