define fuel::systemd (
  $start = true,
  $template_path = 'fuel/systemd/service_template.erb',
  $config_name = 'fuel.conf',
  $service_manage = true,
  ) {

  if !defined(File["/etc/systemd/system/${name}.service.d"]) {
    file { "/etc/systemd/system/${name}.service.d":
      ensure => directory
    }
  }

  file { "/etc/systemd/system/${name}.service.d/${config_name}":
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

  if $start {
    $ensure = 'running'
  } else {
    $ensure = undef
  }

  if $service_manage and ! defined(Service[$title]) {
    service { $name :
      ensure    => $ensure,
      enable    => true,
      require   => Exec['fuel_systemd_reload'],
      subscribe => File["/etc/systemd/system/${name}.service.d/${config_name}"]
    }
  } else {
    Service <| title == $name |> {
      ensure    => $ensure,
      enable    => true,
      require   => Exec['fuel_systemd_reload'],
      subscribe => File["/etc/systemd/system/${name}.service.d/${config_name}"]
    }
  }

}
