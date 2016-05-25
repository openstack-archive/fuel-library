class fuel::nginx::repo(
  $repo_root       = $::fuel::params::repo_root,
  $repo_port       = $::fuel::params::repo_port,
  $service_enabled = true,
  ) inherits fuel::nginx {

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { "${repo_root}/index.html":
    content => '',
  }

  file { "${repo_root}/error.html":
    content => template('fuel/nginx/error.html.erb'),
  }

  file { '/etc/nginx/conf.d/repo.conf':
    content => template('fuel/nginx/repo.conf.erb'),
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

}
