define nailgun::systemd::config {
  file { "/etc/systemd/system/${title}.service.d/":
    ensure      => directory
  }

  file { "/etc/systemd/system/${title}.service.d/fuel.conf":
    content     => template("nailgun/systemd/service_template.erb"),
    owner       => 'root',
    group       => 'root',
    mode        => '0644',
  }
  ->
  exec { "systemd_reload_${title}":
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File["/etc/systemd/system/${title}.service.d/fuel.conf"],
  }
  ->
  service { "${title}":
    ensure      => running,
    enable      => true,
    subscribe   => Exec["systemd_reload_${title}"],
  }
}
