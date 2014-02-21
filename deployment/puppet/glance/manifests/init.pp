#
#
#

class glance(
  $package_ensure = 'present',
) {

  include glance::params

  File {
    ensure  => present,
    owner   => 'glance',
    group   => 'glance',
    mode    => '0640',
    require => Package['glance'],
  }

  file { '/etc/glance/':
    ensure  => directory,
    mode    => '0770',
  }

  group {'glance': gid=> 161, ensure=>present, system=>true}
  user  {'glance': uid=> 161, ensure=>present, system=>true, gid=>"glance", require=>Group['glance']}
  User['glance'] -> Package['glance']
  package { 'glance':
    name   => $::glance::params::package_name,
    ensure => $package_ensure,
  }
}
