class nailgun::nginx(
  $production               = "production",
  $repo_root                = "/var/www/nailgun",
  $staticdir                = "/opt/nailgun/share/nailgun/static",
  $templatedir              = "/opt/nailgun/share/nailgun/static",
  $logdumpdir               = "/var/www/nailgun/dump",
  $service_enabled          = true,
  $ostf_host                = '127.0.0.1',
  $nailgun_host             = '127.0.0.1',
  $listen_https_ip_address  = '0.0.0.0',
  $listen_https_port        = '443',
  $ostf_port                = '8777',
  $nailgun_port             = '8001',
  $ssl_certificate          = '/etc/pki/tls/certs/fuel.crt',
  $ssl_key                  = '/etc/pki/tls/private/fuel.key',
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

  file { [
          "/etc/nginx/conf.d/default.conf",
          "/etc/nginx/conf.d/virtual.conf",
         ]:
    ensure => "absent",
    notify => Service["nginx"],
    before => [
               Class["nailgun::nginx-repo"],
               Class["nailgun::nginx-nailgun"],
               ],
  }

  include ssl

  $node_name='fuel'

  if file_exists_simple("/etc/pki/tls/certs/fuel.crt") == 0 {
    ssl::cert { $node_name:
      alt_names => [ 'fuelmaster' ],
      country   => 'UA',
      org       => 'Mirantis',
      org_unit  => 'Express',
      state     => 'KH',
      city      => 'KH',
    }
  }


  file { "/etc/nginx/conf.d/ssl.conf":
    content =>template("nailgun//ssl.conf.erb"),
    notify       => Service["nginx"],
  } ->

  class { "nailgun::nginx-repo":
    repo_root => $repo_root,
    notify => Service["nginx"],
  }
  class { "nailgun::nginx-service":
    service_enabled => $service_enabled,
  }

  class { 'nailgun::nginx-nailgun':
    staticdir    => $staticdir,
    logdumpdir   => $logdumpdir,
    ostf_host    => $ostf_host,
    nailgun_host => $nailgun_host,
    notify       => Service["nginx"],
  }
}

