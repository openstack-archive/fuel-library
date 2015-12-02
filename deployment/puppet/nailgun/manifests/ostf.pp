class nailgun::ostf(
  $pip_opts,
  $production,
  $use_systemd          = false,
  $venv                 = '/opt/fuel_plugins/ostf',
  $dbuser               = 'ostf',
  $dbpass               = 'ostf',
  $dbname               = 'ostf',
  $dbhost               = '127.0.0.1',
  $dbport               = '5432',
  $nailgun_host         = '127.0.0.1',
  $nailgun_port         = '8000',
  $dbengine             = 'postgresql+psycopg2',
  $host                 = '127.0.0.1',
  $port                 = '8777',
  $logfile              = '/var/log/ostf.log',
  $keystone_host        = '127.0.0.1',
  $keystone_port        = '35357',
  $keystone_ostf_user   = 'ostf',
  $keystone_ostf_pass   = 'ostf',
  $auth_enable          = 'True',
){
  package{'libevent-devel':}
  package{'openssl-devel':}
  if $production !~ /docker/ {
    postgresql::server::db{ $dbname:
      user     => $dbuser,
      password => $dbpass,
      grant    => 'all',
      require => Class['::postgresql::server'],
    }
  }
  case $production {
    'prod', 'docker': {
      package{'fuel-ostf':}

      exec {'ostf-init':
        command => "/usr/bin/ostf-server \
          --after-initialization-environment-hook",
        tries     => 50,
        try_sleep => 5,
      }
      Postgresql::Server::Db<| title == $dbname|> ->
      Package['fuel-ostf'] -> Exec['ostf-init']
      File['/etc/ostf/ostf.conf'] -> Exec['ostf-init']
    }
    'docker-build': {
      package{'fuel-ostf':}
    }
  }
  if ! $use_systemd {
    file { '/etc/supervisord.d/ostf.conf':
      owner   => 'root',
      group   => 'root',
      content => template('nailgun/supervisor/ostf.conf.erb'),
      require => Package['supervisor'],
    }
  }
  file { '/etc/ostf/':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }
  file { '/etc/ostf/ostf.conf':
    owner   => 'root',
    group   => 'root',
    content => template('nailgun/ostf.conf.erb'),
  }
  file { '/var/log/ostf':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
