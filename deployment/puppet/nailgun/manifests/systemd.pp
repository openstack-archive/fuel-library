class nailgun::systemd (
  $services = undef,
) {

  include stdlib

  define nailgun::systemd::config {
    file { "/etc/systemd/system/${title}.service.d/":
      ensure  => directory
    }
    ->
    file { "/etc/systemd/system/${title}.service.d/local.conf":
      content => template("nailgun/systemd/${title}.conf.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      ensure  => file,
      notify  => [ Exec['systemd_reload'], Service["${title}"] ],
    }
    ->
    exec { 'systemd_reload':
      command => '/bin/systemctl daemon-reload',
      refresh => 'true',
    }
    ->
    service { "${title}":
      ensure     => running,
      enable     => true,
    }
  }

  if is_array($services) {
    nailgun::systemd::config {$services: }
  }
}
