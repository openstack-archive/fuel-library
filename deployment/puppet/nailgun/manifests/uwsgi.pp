class nailgun::uwsgi(
  $venv,
  ) {

  file { "/etc/nailgun/uwsgi_nailgun.yaml":
    content => template("nailgun/uwsgi_nailgun.yaml.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Package["uwsgi"],
  }

  exec { "/opt/nailgun/bin/nailgun-uwsgi":
    command => "touch /opt/nailgun/bin/nailgun-uwsgi"
  }

}
