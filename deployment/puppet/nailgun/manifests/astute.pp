class nailgun::astute(
  $rabbitmq_astute_user = 'naily',
  $rabbitmq_astute_password = 'naily',
  $version,
  $gem_source = "http://rubygems.org/",
  ){

  exec { 'install-astute-gem':
    command => "/opt/rbenv/bin/rbenv exec gem install astute --source $gem_source --version $version --no-ri --no-rdoc",
    environment => ['RBENV_ROOT=/opt/rbenv', 'RBENV_VERSION=1.9.3-p484'],
    require => Exec['configure-rubygems'],
    logoutput => true,
  }

  exec { 'configure-rubygems':
    command => '/opt/rbenv/bin/rbenv exec gem sources -r http://rubygems.org/',
    environment => ['RBENV_ROOT=/opt/rbenv', 'RBENV_VERSION=1.9.3-p484'],
    require => Package['rbenv-ruby-1.9.3-p484-0.0.1-1'],
    logoutput => true,
  }

  package { 'rbenv-ruby-1.9.3-p484-0.0.1-1': }

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
