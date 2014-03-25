class nailgun::uwsgi(
  $venv,
  ) {

  if $::physicalprocessorcount <= 8 {
    $physicalprocessorcount = ($::physicalprocessorcount - 1)
  } else {
    $physicalprocessorcount = 8
  }

  package { 'uwsgi':
    ensure => installed,
  }

  file { "/etc/nailgun/uwsgi_nailgun.yaml":
    content => template("nailgun/uwsgi_nailgun.yaml.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Package['uwsgi'],
  }

  exec { '/opt/nailgun/bin/nailgun-uwsgi':
    command => 'touch /opt/nailgun/bin/nailgun-uwsgi',
    provider => 'shell',
  }


  Class[Nailgun::Venv]->
    Exec['/opt/nailgun/bin/nailgun-uwsgi']->
    File['/etc/nailgun/uwsgi_nailgun.yaml']
}
