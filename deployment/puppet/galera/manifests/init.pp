# 
# wget https://launchpad.net/codership-mysql/5.5/5.5.23-23.6/+download/mysql-server-wsrep-5.5.23-23.6-amd64.deb
# wget https://launchpad.net/galera/2.x/23.2.1/+download/galera-23.2.1-amd64.deb
# aptitude install mysql-client libdbd-mysql-perl libdbi-perl
# aptitude install libssl0.9.8
# dpkg -i mysql-server-wsrep-5.5.23-23.6-amd64.deb 
# dpkg -i galera-23.2.1-amd64.deb 
# vi /etc/mysql/conf.d/wsrep.cnf 
# /etc/init.d/mysql start
# 
class galera($cluster_name, $master_ip = false, $node_address = $ipaddress_eth0) {

  include galera::params

  $mysql_user       = $::galera::params::mysql_user
  $mysql_password   = $::galera::params::mysql_password
  $libgalera_prefix = $::galera::params::libgalera_prefix


  case $::osfamily {
    'RedHat': {
      #$pkg_prefix = 'ftp://ftp.sunet.se/pub/databases/relational/mysql/Downloads/MySQL-5.5/'
      $pkg_prefix = '/tmp/'

      package { "mysql-libs" : 
        ensure   => purged,
        before   => [Package['MySQL-client', 'MySQL-shared', 'MySQL-shared-compat', 'galera'], File['/etc/my.cnf']]
      }

      package { 'MySQL-client' :
        ensure   => present,
        provider => $::galera::params::pkg_provider,
        source   => "${pkg_prefix}MySQL-client-5.5.27-1.el6.x86_64.rpm",
        before   => Package['MySQL-shared']
      } 

      package { 'MySQL-shared' :
        ensure   => present,
        provider => $::galera::params::pkg_provider,
        source  => "${pkg_prefix}MySQL-shared-5.5.27-1.el6.x86_64.rpm",
        before   => Package['MySQL-shared-compat']
      } 

      package { 'MySQL-shared-compat' :
        ensure   => present,
        provider => $::galera::params::pkg_provider,
        source => "${pkg_prefix}MySQL-shared-compat-5.5.27-1.el6.x86_64.rpm",
        before   => Package['MySQL-server']
      } 

      file { '/etc/my.cnf' :
        ensure  => present,
        source  => 'puppet:///modules/galera/my.cnf',
        before  => Service['mysql-galera']
      }

      class { 'selinux' :
        mode   => 'disabled',
        before => Package['mysql-libs']
      }

      package { 'wget' :
        ensure => present,
        before => Exec['download-wsrep', 'download-galera']
      }

      exec { "bugfix_create_db" :
        command => "/bin/sleep 15; /usr/bin/mysql_install_db --user=mysql",
        require => Package["MySQL-server"],
        before  => Service['mysql-galera'],
        unless  => "/bin/ls /var/lib/mysql/performance_schema"
      }

    }
    'Debian': {
      package { "mysql-client" :
        ensure => present,
        before => Package["MySQL-server"]
      }
    }
  }

  service { "mysql-galera" :
    name        => "mysql",
    ensure      => "running",
    require     => [Package["MySQL-server", "galera"], File["/etc/mysql/conf.d/wsrep.cnf"]],
    hasrestart  => true,
    hasstatus   => true,
  }

  package { [$::galera::params::libssl_package, $::galera::params::libaio_package] :
    ensure      => present,
    before      => Package["galera", "MySQL-server"]
  }

  package { "MySQL-server" :
    ensure      => present,
    provider    => $::galera::params::pkg_provider,
    source      => "/tmp/${::galera::params::mysql_server_package}",
    require     => Exec["download-wsrep"],
  }

  exec { "download-wsrep" :
    command     => "/usr/bin/wget -P/tmp https://launchpad.net/codership-mysql/5.5/5.5.23-23.6/+download/${::galera::params::mysql_server_package}",
    creates     => "/tmp/${::galera::params::mysql_server_package}"
  }

  package { "galera" :
    ensure      => present,
    provider    => $::galera::params::pkg_provider,
    source      => "/tmp/${::galera::params::galera_package}",
    require     => Exec["download-galera"],
  }

  exec { "download-galera" :
    command     => "/usr/bin/wget -P/tmp https://launchpad.net/galera/2.x/23.2.1/+download/${::galera::params::galera_package}",
    creates     => "/tmp/${::galera::params::galera_package}",
  }

  file { ["/etc/mysql", "/etc/mysql/conf.d" ] :
    ensure => directory,
    before => File["/etc/mysql/conf.d/wsrep.cnf"]
  }

  file { "/etc/mysql/conf.d/wsrep.cnf" :
    ensure      => present,
    content     => template("galera/wsrep.cnf.erb"),
    require     => Package["MySQL-server", "galera"],
  }

  exec { "set-mysql-password" :
    unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
    command     => "/usr/bin/mysql -uroot -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${mysql_user}'@'%' identified by '${mysql_password}';flush privileges;\"",
    require     => Service["mysql-galera"],
    subscribe   => Service["mysql-galera"],
    refreshonly => true,
  }

}
