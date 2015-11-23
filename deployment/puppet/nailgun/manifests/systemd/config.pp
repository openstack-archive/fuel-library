define nailgun::systemd::config {
  file { "/etc/systemd/system/${title}.service.d/local.conf":
    content     => template("nailgun/systemd/service_template.erb"),
    owner       => 'root',
    group       => 'root',
    mode        => '0644',
    notify      => [ Exec["systemd_reload_${title}"], Service["${title}"] ]
  }
  ->
  exec { "systemd_reload_${title}":
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }
  ->
  service { "${title}":
    ensure      => running,
    enable      => true,
  }
}
