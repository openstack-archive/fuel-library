class nailgun::systemd (
  $services = undef,
) {

  include stdlib

  define nailgun::systemd::config {
    file { "/usr/lib/systemd/system/${title}.service":
      content => template("nailgun/systemd/${title}.service.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      ensure  => file
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
