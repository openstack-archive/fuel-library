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
#   (required) Array. This is an array of service names for which local
#   changes will be applied.
#
# [*production*]
#   (required) String. Determine environment.
#   Changes applies only for 'prod' and 'docker' environments.
#

class nailgun::systemd (
  $services,
  $production
) {

include stdlib

case $production {
  'prod', 'docker': {
    if is_array($services) {
      if !empty($services) {
        nailgun::systemd::config { $services: }
      }
    }
  }
  default: { }
}

}
