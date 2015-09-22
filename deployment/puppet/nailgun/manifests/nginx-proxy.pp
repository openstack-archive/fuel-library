class nailgun::nginx-proxy(
  $port     = '2080',
  $resolver = $::ipaddress,
  ){

  file { "/etc/nginx/conf.d/proxy.conf":
    content => template("nailgun/nginx_nailgun_proxy.conf.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => [
                Package["nginx"],
                ],
    notify => Service["nginx"],
  }

}
