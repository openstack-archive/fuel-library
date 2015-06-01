notice('MODULAR: yum-proxy.pp')

$http_proxy_url = hiera('http_proxy_url', undef)
$yum_config     = '/etc/yum.conf'

if $::osfamily == 'RedHat' and $http_proxy_url {
  augeas { 'yum-proxy':
    incl    => $yum_config,
    lens    => 'Yum.lns',
    context => "/file${yum_config}/main",
    changes => "set proxy ${http_proxy_url}",
  }
}
