class nailgun::nginx-service (
  $service_enabled = true,
) {

  if ( $service_enabled == false ){
    $ensure = false
  } else {
    $ensure = 'running'
  }
  file { '/etc/nginx/nginx.conf':
    ensure  => present,
    content => template('nailgun/nginx.conf.erb'),
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
  Package<| title == 'nginx'|> ~> Service<| title == 'nginx'|>
  if !defined(Service['nginx']) {
    notify{ "Module ${module_name} cannot notify service nginx  package update": }
  }
}
