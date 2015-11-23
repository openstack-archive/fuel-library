# == Class: docker::systemd
#
# Systemd units generator for docker containers
#
# === Parameters
#
# [*release*]
#   (required) String. Determine MOS release.
#   This release will use for correct docker container names,
#   e.g. if release == '8.0' and container name is 'astute' -
#   the full container name will be fuel-core-8.0-astute
#
# [*stop_timeout*]
#   (required) Integer. Number of seconds to wait for the container
#   to stop before killing it.
#
# [*containers*]
#   (required) Array. This is an array of container names which should be start
#   as systemd units.
#
# [*depends*]
#   (optional) Hash. This is a hash of container dependencies.
#   Key is a container name, value is a container name
#   which should be started before.
#

class docker::systemd (
  $release = undef,
  $stop_timeout = 30,
  $containers = ['astute', 'cobbler', 'keystone', 'mcollective', 'nailgun',
    'nginx', 'ostf', 'postgres', 'rabbitmq', 'rsync', 'rsyslog'],
  $depends = {
    'astute'      => 'rsync',
    'cobbler'     => 'nginx',
    'keystone'    => 'rabbitmq',
    'mcollective' => 'cobbler',
    'nailgun'     => 'rsyslog',
    'nginx'       => 'ostf',
    'ostf'        => 'nailgun',
    'rsync'       => 'keystone',
    'rsyslog'     => 'astute',
    'rabbitmq'    => 'postgres'
  },
) {
  # No empty release allowed
  validate_string($release)

  docker::systemd::config {$containers:
                            release => $release,
                            depends => $depends,
                            timeout => $stop_timeout}
}

