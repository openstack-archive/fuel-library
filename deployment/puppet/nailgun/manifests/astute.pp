class nailgun::astute(
  $production = 'prod',
  $rabbitmq_host = 'localhost',
  $rabbitmq_astute_user = 'naily',
  $rabbitmq_astute_password = 'naily',
  $version,
  $bootstrap_flavor = 'centos',
  $gem_source = "http://rubygems.org/",
  ){

  $bootstrap_profile = $bootstrap_flavor ? {
    /(?i)centos/                 => 'bootstrap',
    /(?i)ubuntu/                 => 'ubuntu_bootstrap',
    default                      => 'bootstrap',
  }

  # exec { 'install-astute-gem':
  #   command => "gem install astute --source $gem_source --version $version --no-ri --no-rdoc",
  #   require => Exec['configure-rubygems'],
  #   logoutput => true,
  # }

  # exec { 'configure-rubygems':
  #   command => 'gem sources -r http://rubygems.org/',
  #   require => Package['ruby'],
  #   logoutput => true,
  # }

  package { 'rubygem-astute': }

  file { '/usr/bin/astuted':
    content => template('nailgun/astuted.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/etc/astute':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/astute/astuted.conf':
    content => template('nailgun/astuted.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/astute'],
  }

  file { '/var/log/astute':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

}
