class fuel::nginx::repo(
  $repo_root       = $::fuel::params::repo_root,
  $repo_port       = $::fuel::params::repo_port,
  $service_enabled = true,
  ) inherits fuel::nginx {

  file { "${repo_root}/index.html":
    ensure  => present,
    content => '',
  }

  file { '/etc/nginx/conf.d/repo.conf':
    content => template('fuel/nginx/repo.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

}
