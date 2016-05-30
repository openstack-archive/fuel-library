class nailgun::tuningbox::systemd (
  $app_name          = $::nailgun::tuningbox::params::app_name,
  $uwsgi_config_path = $::nailgun::tuningbox::params::keystone_host,
  $pid_path          = $::nailgun::tuningbox::params::keystone_user,
  ) inherits nailgun::tuningbox::params {

  $systemd_script_path = "/etc/systemd/system/${app_name}.service"

  exec { 'systemd_reload':
    command     => '/usr/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  file { "$systemd_script_path":
    content => template("nailgun/tuningbox/tuningbox_systemd.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Exec['systemd_reload']
  }

  service { "${app_name}":
    ensure    => running,
    enable    => true,
    require => File["${systemd_script_path}"]
  }
}
