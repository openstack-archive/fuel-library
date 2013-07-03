#
#
#

class glance(
  $package_ensure = 'present',
# TODO syslog facilities from site.pp
# TODO syslog common level from site.pp
  $syslog_log_facility = 'LOCAL2',
  $syslog_log_level    = 'INFO',
) {

  include glance::params

  File {
    ensure  => present,
    owner   => 'glance',
    group   => 'glance',
    mode    => '0644',
    require => Package['glance'],
  }

  file { '/etc/glance/':
    ensure  => directory,
    mode    => '0770',
  }
  file {"glance-logging.conf":
    content => template('glance/logging.conf.erb'),
    path => "/etc/glance/logging.conf",
    require => File['/etc/glance'],
  }
  file { "glance-all.log":
    path => "/var/log/glance-all.log",
  }
  file { '/etc/rsyslog.d/40-glance.conf':
    ensure => present,
    content => template('glance/rsyslog.d.erb'),
  }

  # We must notify rsyslog and services to apply new logging rules
  include rsyslog::params
  File['/etc/rsyslog.d/40-glance.conf'] ~> Service <| title == "$rsyslog::params::service_name" |>

  File['glance-logging.conf'] ~> Service <| title == "$rsyslog::params::api_service_name" |> 
  File['glance-logging.conf'] ~> Service <| title == "$rsyslog::params::registry_service_name" |>

  group {'glance': gid=> 161, ensure=>present, system=>true}
  user  {'glance': uid=> 161, ensure=>present, system=>true, gid=>"glance", require=>Group['glance']}
  User['glance'] -> Package['glance']
  package { 'glance':
    name   => $::glance::params::package_name,
    ensure => $package_ensure,
  }
}
