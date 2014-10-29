class nailgun::nginx-service (
  $service_enabled = true,
) {

  if ( $service_enabled == false ){
    $ensure = false
  } else {
    $ensure = 'running'
  }
  file { '/etc/nginx/nginx.conf':
    ensure  => installed,
    mode    => '0644',
    content => template('nailgun/nginx.conf.erb'),
    require => Package['nginx'],
  }
  service { 'nginx':
    enable  => $service_enabled,
    ensure  => $ensure,
    require => File['/etc/nginx/nginx.conf'],
  }
  Package<| title == 'nginx'|> ~> Service<| title == 'nginx'|>
  if !defined(Service['nginx']) {
    notify{ "Module ${module_name} cannot notify service nginx  package update": }
  }
}
