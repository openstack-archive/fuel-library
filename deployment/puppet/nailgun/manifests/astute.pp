class nailgun::astute(
  $production = 'prod',
  $rabbitmq_host = 'localhost',
  $rabbitmq_astute_user = 'naily',
  $rabbitmq_astute_password = 'naily',
  $gem_source = "http://rubygems.org/",
  ){

  $bootstrap_profile = 'ubuntu_bootstrap'

  case $::operatingsystem {
    /(?i)(centos|redhat)/: {
      case $::operatingsystemrelease {
        /6.+/: {
          package { 'ruby21-rubygem-astute': }
        }
        /7.+/: {
          package { 'rubygem-astute': }
        }
      }
    }
  }

  file { '/etc/sysconfig/astute':
    content => template('nailgun/astute.sysconfig.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644'
  } ~> Service <| title == 'astute' |>

  file { '/usr/bin/astuted':
    content => template('nailgun/astuted.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  } ~> Service <| title == 'astute' |>

  file {"/etc/astute":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file {"/etc/astute/astuted.conf":
    content => template('nailgun/astuted.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/astute'],
  } ~> Service <| title == 'astute' |>

  file {"/var/log/astute":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

}
