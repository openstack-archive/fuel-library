class nailgun::astute(
  $production               = $::nailgun::params::production,
  $rabbitmq_host            = $::nailgun::params::rabbitmq_host,
  $rabbitmq_astute_user     = $::nailgun::params::rabbitmq_astute_user,
  $rabbitmq_astute_password = $::nailgun::params::rabbitmq_astute_password,
  $bootstrap_flavor         = $::nailgun::params::bootstrap_flavor,
  $gem_source               = $::nailgun::params::gem_source,
  ) inherits nailgun::params {

  $bootstrap_profile = $bootstrap_flavor ? {
    /(?i)centos/                 => 'bootstrap',
    /(?i)ubuntu/                 => 'ubuntu_bootstrap',
    default                      => 'bootstrap',
  }

  package { 'ruby21-rubygem-astute': }

  file { '/usr/bin/astuted':
    content => template('nailgun/astuted.erb'),
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

  file {"/etc/astute":
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

  file {"/etc/astute/astuted.conf":
    content => template("nailgun/astuted.conf.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File["/etc/astute"],
  }

  file {"/var/log/astute":
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

}
