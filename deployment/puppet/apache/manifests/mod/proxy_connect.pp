class apache::mod::proxy_connect (
  $apache_version  = $::apache::apache_version,
) {
  if versioncmp($apache_version, '2.3.5') >= 0 {
    ::apache::mod { 'proxy_connect': }
  }
}
