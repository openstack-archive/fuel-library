class nailgun::systemd (
  $services = [],
  $production
) {

include stdlib

case $production {
  'prod', 'docker': {
    if !empty($services) {
      nailgun::systemd::config { $services: }
    }
  }
  default: { }
}

}
