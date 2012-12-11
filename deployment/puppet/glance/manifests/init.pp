class glance(
  $package_ensure = $::openstack_version['glance']
) {

  include glance::params

  file { '/etc/glance/':
    ensure  => directory,
    owner   => 'glance',
    group   => 'root',
    mode    => '0770',
    require => Package['glance']
  }
  group {'glance': gid=> 161, ensure=>present, system=>true}
  user  {'glance': uid=> 161, ensure=>present, system=>true, group=>"glance", require=>Group['glance']}
  package { 'glance':
    name   => $::glance::params::package_name,
    ensure => $package_ensure,
  }
}
