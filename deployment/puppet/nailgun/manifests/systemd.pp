# == Class: nailgun::systemd
#
# Apply local settings for nailgun services.
#
# At this moment only start/stop timeouts
# and syslog identificators.
#
# === Parameters
#
# [*services*]
#   (required) Array or String. This is an array of service names (or just service name as tring)
#   for which local changes will be applied.
#
# [*production*]
#   (required) String. Determine environment.
#   Changes applies only for 'prod' and 'docker' environments.
#

class nailgun::systemd (
  $services,
  $production
) {

  case $production {
    'prod', 'docker': {
      if !empty($services) {
        nailgun::systemd::config { $services: }
      }
    }
    default: { }
  }

}
