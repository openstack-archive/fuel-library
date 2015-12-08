define nailgun::systemd::config ($real_exec) {
  file { "/etc/systemd/system/${title}.service.d/":
    ensure => directory
  }

  file { "/etc/systemd/system/${title}.service.d/fuel.conf":
    content => template('nailgun/systemd/service_template.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Exec['nailgun_systemd_reload']
  }

  if !defined(Exec['nailgun_systemd_reload']) {
    exec { 'nailgun_systemd_reload':
      command     => '/usr/bin/systemctl daemon-reload',
      refreshonly => true,
    }
  }

  service { "${title}":
    ensure    => running,
    enable    => true,
    require   => Exec['nailgun_systemd_reload'],
    subscribe => File["/etc/systemd/system/${title}.service.d/fuel.conf"]
  }
}
