#
# docker::systemd::config resource deploys systemd units for fuel-related
# docker containers and enable to running a containers as a standard
# system service. This resource doesn't changes any state of a container.

# Variables:
#
# release - will use for correct docker container names
#   e.g. if release == '8.0' and container name is 'astute' -
#   the full container name will be fuel-core-8.0-astute
#
# depends - this is a hash which describes dependencies of containers
#   Key is a container name which apply setting, value is a container name
#   which should be started before.
#
# timeout - Number of seconds to wait for the container to stop before killing it.
#

define docker::systemd::config( $release, $depends, $timeout ) {
  file { "/usr/lib/systemd/system/docker-${title}.service":
    ensure  => file,
    content => template('docker/systemd/template.service.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service["docker-${title}"]
  }

  # We use ensure => undef to prevent unnecessary start service
  # because at first boot time, the container is launched by dockerctl
  service { "docker-${title}":
    enable => true,
  }
}
