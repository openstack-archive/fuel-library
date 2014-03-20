class nailgun::naily(
  $rabbitmq_naily_user = 'naily',
  $rabbitmq_naily_password = 'naily',
  $version,
  $gem_source = "https://rubygems.org/",
  ){

  exec { 'install-naily-gem':
    command => "gem install naily --source $gem_source --version $version --no-ri --no-rdoc",
    logoutput => true,
  }

  package { 'ruby-2.1.1-1.1.mira1.x86_64': }

  file { '/usr/bin/nailyd':
    content => template('nailgun/nailyd.erb'),
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

  #file { '/usr/bin/astute':
  #  content => template('nailgun/astute.erb'),
  #  owner => 'root',
  #  group => 'root',
  #  mode => 0755,
  #}

  file {"/etc/naily":
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

  file {"/etc/naily/nailyd.conf":
    content => template("nailgun/nailyd.conf.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File["/etc/naily"],
  }

  file {"/var/log/naily":
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }

}
