class fuel::nginx inherits fuel::params {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  ensure_packages(['nginx'])
  Package['nginx'] ~> Service['nginx']

  file { ['/etc/nginx/conf.d/default.conf',
          '/etc/nginx/conf.d/virtual.conf',
          '/etc/nginx/conf.d/ssl.conf']:
    ensure  => 'file',
    content => "# This file managed by Puppet\n# and should exists to prevent fail on package upgrade\n",
    notify  => Service['nginx'],
    before  => File["/etc/nginx/nginx.conf"],
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
