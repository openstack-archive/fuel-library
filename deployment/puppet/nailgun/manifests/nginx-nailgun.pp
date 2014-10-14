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

  file { '/etc/nginx/conf.d/nailgun_ssl.conf':
    content => template('nailgun/nginx_nailgun_ssl.conf.erb'),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Package['nginx'],
    notify => Service['nginx'],
  }
  file { '/etc/nginx/ssl':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
    require => Package['nginx'],
    notify => Service['nginx'],
  }
  exec { 'Generate SSL sert':
    cwd => '/etc/nginx/ssl',
    command => '/usr/bin/openssl req -nodes -x509 -newkey rsa:4096 -keyout cert.key -out cert.crt -days 356 -subj "/C=US/ST=Oregon/L=Portland/O=IT/CN=mirantis.com"',
    creates => '/etc/nginx/ssl/cert.crt',
    require => File['/etc/nginx/ssl'],
    notify => Service['nginx'],
  }
}
