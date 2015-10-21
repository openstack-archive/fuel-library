class nailgun::astute(
  $production = 'prod',
  $rabbitmq_host = 'localhost',
  $rabbitmq_astute_user = 'naily',
  $rabbitmq_astute_password = 'naily',
  $bootstrap_flavor = 'centos',
  $gem_source = "http://rubygems.org/",
  ){

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
