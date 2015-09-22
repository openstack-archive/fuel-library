notice('MODULAR: pkg-proxy-del.pp')

case $::osfamily {
  'debian': {
    class {'apt':}
  }
  default: {
    warning("$::osfamily osfamily is not supported by pkg-proxy-del.pp task. Skipping package proxy removal.")
  }
}
