define fuel::systemd ($start = true, $template_path = 'fuel/systemd/service_template.erb', $config_name = 'fuel.conf') {
  file { "/etc/systemd/system/${title}.service.d/":
    ensure => directory
  }

  file { "/etc/systemd/system/${title}.service.d/${config_name}":
    content => template($template_path),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Exec['fuel_systemd_reload']
  }

  if !defined(Exec['fuel_systemd_reload']) {
    exec { 'fuel_systemd_reload':
      command     => '/usr/bin/systemctl daemon-reload',
      refreshonly => true,
    }
  }

  if !defined(Service[$title]) {
    if $start {
      service { "${title}":
        ensure    => running,
        enable    => true,
        require   => Exec['fuel_systemd_reload'],
        subscribe => File["/etc/systemd/system/${title}.service.d/${config_name}"]
      }
    }
    else {
      service { "${title}":
        enable    => true,
        require   => Exec['fuel_systemd_reload'],
        subscribe => File["/etc/systemd/system/${title}.service.d/${config_name}"]
      }
    }
  }
}
