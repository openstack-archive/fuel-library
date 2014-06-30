class nailgun::nginx(
  $production = "production",
  $repo_root = "/var/www/nailgun",
  $staticdir = "/opt/nailgun/share/nailgun/static",
  $templatedir = "/opt/nailgun/share/nailgun/static",
  $logdumpdir = "/var/www/nailgun/dump",
  $service_enabled = true,
  $ostf_host = '127.0.0.1',
  $keystone_host = '127.0.0.1',
  $nailgun_host = '127.0.0.1',
  ) {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  anchor { "nginx-begin": }
  anchor { "nginx-end": }

  Anchor<| title == "nginx-begin" |> ->
  Class["nailgun::nginx-repo"] ->
  Class["nailgun::nginx-nailgun"] ->
  Anchor<| title == "nginx-end" |>

  package { 'nginx':
    ensure => latest,
  }

  file { ["/etc/nginx/conf.d/default.conf",
          "/etc/nginx/conf.d/virtual.conf",
          "/etc/nginx/conf.d/ssl.conf"]:
    ensure => "absent",
    notify => Service["nginx"],
    before => [
               Class["nailgun::nginx-repo"],
               Class["nailgun::nginx-nailgun"],
               ],
  }

  class { "nailgun::nginx-repo":
    repo_root => $repo_root,
    notify => Service["nginx"],
  }
  class { "nailgun::nginx-service":
    service_enabled => $service_enabled,
  }

  class { 'nailgun::nginx-nailgun':
    staticdir     => $staticdir,
    logdumpdir    => $logdumpdir,
    ostf_host     => $ostf_host,
    keystone_host => $keystone_host,
    nailgun_host  => $nailgun_host,
    notify        => Service["nginx"],
  }
}

