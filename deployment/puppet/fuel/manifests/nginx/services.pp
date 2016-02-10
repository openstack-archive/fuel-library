class fuel::nginx::services (
  $staticdir       = $::fuel::params::staticdir,
  $logdumpdir      = $::fuel::params::logdumpdir,
  $ostf_host       = $::fuel::params::ostf_host,
  $ostf_port       = $::fuel::params::ostf_port,
  $keystone_host   = $::fuel::params::keystone_host,
  $keystone_port   = $::fuel::params::keystone_port,
  $nailgun_host    = $::fuel::params::nailgun_host,
  $nailgun_port    = $::fuel::params::nailgun_internal_port,
  $ssl_enabled     = false,
  $force_https     = undef,
  $service_enabled = true,
  ) inherits fuel::nginx {

  if $ssl_enabled and $force_https {
    $plain_http = false
  } else {
    $plain_http = true
  }

  file { '/etc/nginx/conf.d/services.conf':
    content => template('fuel/nginx/services.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  file { ['/var/lib/fuel',
          '/var/lib/fuel/keys',
          '/var/lib/fuel/keys/master',
          '/var/lib/fuel/keys/master/nginx',
    ]:
    ensure => 'directory',
  }

  if $ssl_enabled {
    $ips = inline_template('<%= @interfaces.split(",").reject{ |iface| iface =~ /^(lo|docker)/ }.map {|iface| scope.lookupvar("ipaddress_#{iface}")}.compact.join(",") %>')
    openssl::certificate::x509 { 'nginx':
      ensure       => present,
      country      => 'US',
      organization => 'Fuel',
      commonname   => 'fuel.master.local',
      altnames     => union(split($ips, ','), [$nailgun_host]),
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
    } -> File["/etc/nginx/conf.d/services.conf"]
  }
}
