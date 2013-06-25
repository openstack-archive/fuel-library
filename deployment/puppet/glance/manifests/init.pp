class glance(
  $package_ensure = 'present',
  $syslog_log_facility = 'LOCAL2',
) {

  include glance::params

  file { '/etc/glance/':
    ensure  => directory,
    owner   => 'glance',
    group   => 'glance',
    mode    => '0770',
    require => Package['glance']
  }
  file {"glance-logging.conf":
    content => template('glance/logging.conf.erb'),
    path => "/etc/glance/logging.conf",
    owner => "glance",
    group => "glance",
    require => File['/etc/glance/'],
  }
  file { "glance-all.log":
    path => "/var/log/glance-all.log",
    owner => "glance",
    group => "glance",
    mode => "0644",
  }
  file { '/etc/rsyslog.d/glance.conf':
    ensure => present,
    content => template('glance/rsyslog.d.erb'),
  }
  
  group {'glance': gid=> 161, ensure=>present, system=>true}
  user  {'glance': uid=> 161, ensure=>present, system=>true, gid=>"glance", require=>Group['glance']}
  User['glance'] -> Package['glance']
  package { 'glance':
    name   => $::glance::params::package_name,
    ensure => $package_ensure,
  }
}
