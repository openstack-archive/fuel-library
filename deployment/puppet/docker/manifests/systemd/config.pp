define docker::systemd::config( $release, $depends, $timeout ) {
  file { "/usr/lib/systemd/system/docker-${title}.service":
    ensure  => file,
    content => template('docker/systemd/template.service.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
  ->
  # Do not run, because service should be just enabled
  # and first run executed from dockerctl, but not from systemctl
  exec { "Enable ${title} container":
    command => "/usr/bin/systemctl enable docker-${title}.service"
  }
}
