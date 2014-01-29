class ironic::supervisor(
  $venv = $::ironic::params::venv,
  ) inherits ironic::params {

  ironic::packages::ironic_safe_package { "supervisor": }

  file { "/etc/rc.d/init.d/supervisord":
    source => 'puppet:///modules/ironic/supervisord',
    owner => 'root',
    group => 'root',
    mode => 0755,
    require => Package["supervisor"],
    notify => Service["supervisord"],
  }

  file { "/etc/supervisord.conf":
    content => template("ironic/supervisord.conf.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Package["supervisor"],
    notify => Service["supervisord"],
  }

  service { "supervisord":
    ensure => "running",
    enable => true,
    require => [
                Package["supervisor"],
                Service["rabbitmq-server"],
                ],
  }

}
