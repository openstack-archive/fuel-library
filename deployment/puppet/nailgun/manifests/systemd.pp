class nailgun::systemd (
  $services = [],
) {

include stdlib

if !empty($services) {
  nailgun::systemd::config { $services: }
  }
}
