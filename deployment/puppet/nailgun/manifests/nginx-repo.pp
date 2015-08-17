class nailgun::nginx-repo(
  $repo_root = "/var/www/nailgun",
  $ubuntu_repo = "http://archive.ubuntu.com/ubuntu",
  $mos_repo    = "http://mirror.fuel-infra.org/mos-repos",
  ){

  file { "/etc/nginx/conf.d/repo.conf":
    content => template("nailgun/nginx_nailgun_repo.conf.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => [
                Package["nginx"],
                ],
    notify => Service["nginx"],
  }

}
