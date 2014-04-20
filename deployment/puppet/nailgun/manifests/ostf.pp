class nailgun::ostf(
  $pip_opts,
  $production,
  $venv           = '/opt/fuel_plugins/ostf',
  $dbuser         = 'ostf',
  $dbpass         = 'ostf',
  $dbname         = 'ostf',
  $dbhost         = '127.0.0.1',
  $dbport         = '5432',
  $nailgun_host   = '127.0.0.1',
  $nailgun_port   = '8000',
  $dbengine       = 'postgresql+psycopg2',
  $host           = '127.0.0.1',
  $port           = '8777',
  $logfile        = '/var/log/ostf.log',
  $debug          = false,
){
  package{'libevent-devel':}
  package{'openssl-devel':}
  if $production !~ /docker/ {
    postgresql::db{ $dbname:
      user     => $dbuser,
      password => $dbpass,
      grant    => 'all',
      require => Class['::postgresql::server'],
    }
    Postgresql::Db[$dbname] ->
    Exec['ostf-init']
  }
  case $production {
    /(prod|docker)/: {
      package{'fuel-ostf':}

      exec {'ostf-init':
        command => "/usr/bin/ostf-server \
          --host=${host} --port=${port} --log_file=${logfile} \
          --dbpath '${dbengine}://${dbuser}:${dbpass}@${dbhost}:${dbport}/${dbname}' \
          --after-initialization-environment-hook || /bin/true",
        require => [
          Package["fuel-ostf"],
        ],
        before => Class['nailgun::supervisor'],
      }
    }
    /dev/: {
      nailgun::venv::venv{'ostf-venv':
        venv     => $venv,
        ensure   => 'present',
        opts     => "--system-site-packages",
        pip_opts => $pip_opts,
      }
      Nailgun::Venv::Pip {
        venv    => $venv,
        opts => "$pip_opts",
        require => [
          Nailgun::Venv::Venv['ostf-venv'],
          Package['libevent-devel'],
          Package['openssl-devel'],
          Package['postgresql-devel'],
        ],
      }
      file { "$venv/pip-requires.txt":
        source => 'puppet:///modules/nailgun/venv-ostf.txt',
        owner => 'root',
        group => 'root',
        mode => 0755,
      }->
      nailgun::venv::pip { "${venv}_setuptools-git":
        package => 'setuptools-git==1.0',
      }->
      nailgun::venv::pip { "${venv}_d2to1":
        package => 'd2to1==0.2.10',
      }->
      nailgun::venv::pip { "${venv}_pbr":
        package => 'pbr==0.5.21',
      }->
      nailgun::venv::pip { "${venv}_ostf-req":
        package => "-r $venv/pip-requires.txt",
      }->
      nailgun::venv::pip { "${venv}_ostf":
        package => 'fuel-ostf',
      }
      exec {'ostf-init':
        command => "$venv/bin/ostf-server \
          --host=${host} --port=${port} --log_file=${logfile} \
          --dbpath '${dbengine}://${dbuser}:${dbpass}@${dbhost}:${dbport}/${dbname}' \
          --after-initialization-environment-hook || /bin/true",
        require => [
          Postgresql::Db[$dbname],
          Nailgun::Venv::Pip["${venv}_ostf-req"],
          Nailgun::Venv::Pip["${venv}_ostf"],
        ],
        before => Class['nailgun::supervisor'],
      }
    }
  }
  file { '/etc/supervisord.d/ostf.conf':
    owner   => 'root',
    group   => 'root',
    content => template('nailgun/supervisor/ostf.conf.erb'),
    require => Package['supervisor'],
  }
  file { '/etc/ostf/':
    ensure => directory,
    owner  => 'root,'
    group  => 'root',
    mode   => '0750',
  }
  file { '/etc/ostf/ostf.conf':
    owner   => 'root',
    group   => 'root',
    content => template('nailgun/supervisor/ostf-service.conf.erb'),
    require => Package['supervisor'],
  }
}
