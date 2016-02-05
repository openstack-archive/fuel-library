# Class configures overall nginx for Nailgun
#
# Parameters
#
# [*ssl_enabled*]
#   (optional) enables certificate generation for nginx SSL
#
class nailgun::nginx(
  $production = 'production',
  $repo_root = '/var/www/nailgun',
  $staticdir = '/opt/nailgun/share/nailgun/static',
  $templatedir = '/opt/nailgun/share/nailgun/static',
  $logdumpdir = '/var/dump',
  $service_enabled = true,
  $ostf_host = '127.0.0.1',
  $keystone_host = '127.0.0.1',
  $nailgun_host = '127.0.0.1',
  $ssl_enabled = false,
  $force_https = undef,
  ) {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  anchor { 'nginx-begin': }
  anchor { 'nginx-end': }

  Anchor<| title == 'nginx-begin' |> ->
  Class['nailgun::nginx_repo'] ->
  Class['nailgun::nginx_nailgun'] ->
  Anchor<| title == 'nginx-end' |>

  package { 'nginx':
    ensure => latest,
  }

  file { ['/var/lib/fuel',
          '/var/lib/fuel/keys',
          '/var/lib/fuel/keys/master',
          '/var/lib/fuel/keys/master/nginx',
    ]:
    ensure => 'directory',
  }

  file { ['/etc/nginx/conf.d/default.conf',
          '/etc/nginx/conf.d/virtual.conf',
          '/etc/nginx/conf.d/ssl.conf']:
    ensure => 'absent',
    notify => Service['nginx'],
    before => [
      Class['nailgun::nginx_repo'],
      Class['nailgun::nginx_nailgun'],
    ],
  }

  class { '::nailgun::nginx_repo':
    repo_root => $repo_root,
    notify    => Service['nginx'],
  }

  if $ssl_enabled {
    $ips = inline_template('<%= @interfaces.split(",").reject{ |iface| iface =~ /^(lo|docker)/ }.map {|iface| scope.lookupvar("ipaddress_#{iface}")}.compact.join(",") %>')
    openssl::certificate::x509 { 'nginx':
      ensure       => present,
      country      => 'US',
      organization => 'Fuel',
      commonname   => 'fuel.master.local',
      altnames     => split($ips, ','),
      state        => 'California',
      unit         => 'Fuel Deployment Team',
      email        => 'root@fuel.master.local',
      days         => 3650,
      base_dir     => '/var/lib/fuel/keys/master/nginx/',
      owner        => 'root',
      group        => 'root',
      force        => false,
      require      => File['/var/lib/fuel/keys/master/nginx'],
      cnf_tpl      => 'openssl/cert.cnf.erb',
    }
  }

  class { '::nailgun::nginx_service':
    service_enabled => $service_enabled,
  }

  class { '::nailgun::nginx_nailgun':
    staticdir     => $staticdir,
    logdumpdir    => $logdumpdir,
    ostf_host     => $ostf_host,
    keystone_host => $keystone_host,
    nailgun_host  => $nailgun_host,
    notify        => Service['nginx'],
    ssl_enabled   => $ssl_enabled,
    force_https   => $force_https,
  }
}

