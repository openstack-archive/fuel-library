notice('MODULAR: pkg-proxy-add.pp')
$pkg_proxy_server = hiera('pkg_proxy_server', hiera('master_ip'))
$pkg_proxy_port = hiera('pkg_proxy_port', '2080')

case $::osfamily {
  'debian': {
    class {'apt':
      proxy => {
        'host' => $pkg_proxy_server,
        'port' => $pkg_proxy_port,
      }
    }
  }
  default: {
    warning("$::osfamily osfamily is not supported by pkg-proxy-add.pp task. Skipping package proxy configuration.")
  }
}
