class nailgun::nginx-service {
  service { "nginx":
    enable => true,
    ensure => "running",
    require => Package["nginx"],
  }
  Package<| title == 'nginx'|> ~> Service<| title == 'nginx'|>
  if !defined(Service['nginx']) {
    notify{ "Module ${module_name} cannot notify service nginx  package update": }
  }
}
