class nailgun::nginx-nailgun(
  $staticdir,
  $logdumpdir,
  $nailgun_host = '127.0.0.1',
  $ostf_host = '127.0.0.1',
  $keystone_host = '127.0.0.1',
  ) {

  file { '/etc/nginx/conf.d/nailgun.conf':
    content => template('nailgun/nginx_nailgun.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => Package['nginx'],
    notify  => Service['nginx'],
  }
}
