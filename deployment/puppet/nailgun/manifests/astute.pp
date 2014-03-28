class nailgun::astute(
  $production = 'prod',
  $rabbitmq_host = 'localhost',
  $rabbitmq_astute_user = 'naily',
  $rabbitmq_astute_password = 'naily',
  $version,
  $rbenv_version = '1.9.3-p484',
  $gem_source = "http://rubygems.org/",
  ){

  if $production != "dev" {
    package { 'rubygems-astute':
      ensure => latest,
    }
    #TODO(mattymo): Remove naily package when astute is fully merged with naily
    package { 'rubygems-naily':
      ensure => latest,
    }
  } else {
    exec { 'install-astute-gem':
      command => "/opt/rbenv/bin/rbenv exec gem install astute --source $gem_source --version $version --no-ri --no-rdoc",
      environment => ['RBENV_ROOT=/opt/rbenv', "RBENV_VERSION=${rbenv_version}"],
      require => Exec['configure-rubygems'],
      logoutput => true,
    }

    exec { 'configure-rubygems':
      command => '/opt/rbenv/bin/rbenv exec gem sources -r http://rubygems.org/',
      environment => ['RBENV_ROOT=/opt/rbenv', "RBENV_VERSION=${rbenv_version}"],
      require => Package['rbenv-ruby-1.9.3-p484-0.0.1-1'],
      logoutput => true,
    }

    package { 'rbenv-ruby-1.9.3-p484-0.0.1-1': }
  }
  #TODO(mattymo): put these files in astute package
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
