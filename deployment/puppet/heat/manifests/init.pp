class heat(
  $package_ensure     = 'present',
  $verbose            = 'False',
  $debug              = 'False',
  $rabbit_host        = '127.0.0.1',
  $rabbit_port        = 5672,
  $rabbit_hosts       = undef,
  $rabbit_userid      = 'guest',
  $rabbit_password    = '',
  $rabbit_virtualhost = '/',
) {

  include heat::params

  File {
    require => Package['heat-common'],
  }

  group { 'heat':
    name    => 'heat',
    require => Package['heat-common'],
  }

  user { 'heat':
    name    => 'heat',
    gid     => 'heat',
    groups  => ['heat'],
    system  => true,
    require => Package['heat-common'],
  }

  file { '/etc/heat/':
    ensure  => directory,
    owner   => 'heat',
    group   => 'heat',
    mode    => '0750',
  }

  package { 'heat-common':
    ensure => $package_ensure,
    name   => $::heat::params::common_package_name,
  }

#  Package['heat-common'] -> Heat_config<||>

}
