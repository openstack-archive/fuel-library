class apt::proxy (
  $proxy = undef,
  $ensure = present,
  ) {
  
  if ($proxy) {
    $proxy_host = inline_template("<%= URI.parse(@proxy).host %>")
    $proxy_port = inline_template("<%= URI.parse(@proxy).port %>")
  }

  include apt::update

  $apt_conf_d = $apt::params::apt_conf_d

  if ($proxy_host) {
    file { 'configure-apt-proxy':
      path    => "${apt_conf_d}/proxy",
      content => "Acquire::http::Proxy \"http://${proxy_host}:${proxy_port}\";",
      notify  => Exec['apt_update'],
    }
  }
}