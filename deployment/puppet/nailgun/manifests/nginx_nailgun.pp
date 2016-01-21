# Class configures nginx for nailgun
#
# Parameters:
# [*ssl_enabled*]
#  (optional) enables SSL for nailgun UI part
#
class nailgun::nginx_nailgun(
  $staticdir,
  $logdumpdir,
  $nailgun_host  = '127.0.0.1',
  $ostf_host     = '127.0.0.1',
  $keystone_host = '127.0.0.1',
  $ssl_enabled   = false,
  $force_https   = undef,
  ) {

  if $ssl_enabled and $force_https {
    $plain_http = false
  } else {
    $plain_http = true
  }

  if $ssl_enabled {
    $dhparam = '/etc/pki/tls/dhparam.pem'

    exec { 'create new dhparam file':
      environment => 'RANDFILE=/root/.rnd',
      path        => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
      command     => "openssl dhparam -rand /dev/urandom -out ${dhparam} 2048",
      creates     => $dhparam,
    }
  }

  file { '/etc/nginx/conf.d/nailgun.conf':
    content => template('nailgun/nginx_nailgun.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }
}
