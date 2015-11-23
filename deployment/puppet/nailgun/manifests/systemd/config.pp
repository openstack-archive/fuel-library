define nailgun::systemd::config ($tag = undef) {
  file { "/etc/systemd/system/${title}.service.d/":
    ensure  => directory
  }
  ->
  file { "/etc/systemd/system/${title}.service.d/local.conf":
    content     => template("nailgun/systemd/service_template.erb"),
    owner       => 'root',
    group       => 'root',
    mode        => '0644',
    ensure      => file,
    notify      => Service["${title}"],
  }
  ->
  exec { "systemd_reload_${title}":
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File["/etc/systemd/system/${title}.service.d/local.conf"]
  }
  ->
  service { "${title}":
    ensure      => running,
    enable      => true,
  }
}
