class glance(
  $package_ensure = 'present'
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
##TODO add rsyslog module config
  file { '/etc/rsyslog.d/glance.conf':
    ensure => present,
    content => "local2.* -/var/log/glance-all.log"
  }
  
  group {'glance': gid=> 161, ensure=>present, system=>true}
  user  {'glance': uid=> 161, ensure=>present, system=>true, gid=>"glance", require=>Group['glance']}
  User['glance'] -> Package['glance']
  package { 'glance':
    name   => $::glance::params::package_name,
    ensure => $package_ensure,
  }
}
