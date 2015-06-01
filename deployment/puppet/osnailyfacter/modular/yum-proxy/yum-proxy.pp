notice('MODULAR: yum-proxy.pp')

$http_proxy_url = hiera('http_proxy_url', undef)
$yum_config     = '/etc/yum.conf'

if $::osfamily == 'RedHat' {
  # remove proxy if unset
  if $http_proxy_url == undef or $http_proxy_url == '' {
    $changes = 'rm proxy'
  } else { # set the proxy if we have a setting
    $changes = "set proxy ${http_proxy_url}"
  }

  augeas { 'yum-proxy':
    incl    => $yum_config,
    lens    => 'Yum.lns',
    context => "/file${yum_config}/main",
    changes => $changes
  }
}
