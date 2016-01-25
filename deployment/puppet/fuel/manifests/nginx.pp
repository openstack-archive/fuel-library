class fuel::nginx inherits fuel::params {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  package { 'nginx':
    ensure => latest,
    notify => Service['nginx'],
  }

  file { ['/etc/nginx/conf.d/default.conf',
          '/etc/nginx/conf.d/virtual.conf',
          '/etc/nginx/conf.d/ssl.conf']:
    ensure => 'absent',
    notify => Service['nginx'],
    before => File["/etc/nginx/nginx.conf"],
  }

  if ( $service_enabled == false ){
    $ensure = false
  } else {
    $ensure = 'running'
  }

  file { '/etc/nginx/nginx.conf':
    ensure  => present,
    content => template('fuel/nginx/nginx.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  service { 'nginx':
    ensure  => $ensure,
    enable  => $service_enabled,
    require => File['/etc/nginx/nginx.conf'],
  }

}
