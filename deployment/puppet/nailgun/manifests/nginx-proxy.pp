# == Class: nailgun::nginx-proxy
#
# This class is used to configure proxy in nginx.
#
# === Parameters:
#
# [*port*]
#   (optional) the port for proxy to listen on.
#   Defaults to '2080'
#
# [*resolver*]
#   (optional) nginx location 'resolver' parameter.
#   Defaults to $::ipaddress fact.
#
class nailgun::nginx-proxy(
  $port     = '2080',
  $resolver = $::ipaddress,
  ){
  file { "/etc/nginx/conf.d/proxy.conf":
    content => template("nailgun/nginx_nailgun_proxy.conf.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => Package["nginx"],
    notify  => Service["nginx"],
  }
}
