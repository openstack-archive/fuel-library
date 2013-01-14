class glance(
  $package_ensure = 'present'
) {

  include glance::params



  file { '/etc/glance/':
    ensure  => directory,
    owner   => 'glance',
    group   => 'root',
    mode    => '0770',
    require => Package['glance']
  }
file {"glance-logging.conf": 
source=>"puppet:///modules/glance/logging.conf",
path => "/etc/glance/logging.conf",
owner => "glance",
group => "glance",
require => [User['glance'],Group['glance'],File['/etc/glance/']]
}
  group {'glance': gid=> 161, ensure=>present, system=>true}
  user  {'glance': uid=> 161, ensure=>present, system=>true, gid=>"glance", require=>Group['glance']}
  User['glance'] -> Package['glance']
  package { 'glance':
    name   => $::glance::params::package_name,
    ensure => $package_ensure,
  }
}
