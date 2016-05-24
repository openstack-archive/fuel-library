class nailgun::nginx-repo(
  $repo_root = "/var/www/nailgun",
  ){

  File {
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { "${repo_root}/index.html":
      ensure  => present,
          content => '',
  }

  file { "${repo_root}/error.html":
    content => template('nailgun/nginx_nailgun_repo.error.html.erb'),
  }

  file { "/etc/nginx/conf.d/repo.conf":
    content => template("nailgun/nginx_nailgun_repo.conf.erb"),
    require => [
                Package["nginx"],
                ],
    notify => Service["nginx"],
  }

}
