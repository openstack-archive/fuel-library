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

  $mysql_user     = $::galera::params::mysql_user
  $mysql_password = $::galera::params::mysql_password

  service { "mysql-galera" :
    name        => "mysql",
    ensure      => "running",
    require     => [Package["mysql-server-wsrep", "galera"], File["/etc/mysql/conf.d/wsrep.cnf"]],
    hasrestart  => true,
    # hasstatus   => true, // http://projects.puppetlabs.com/issues/5610
  }

  package { [$::galera::params::mysql_client_package, $::galera::params::libssl_package] :
    ensure      => present,
  }

  package { "mysql-server-wsrep" :
    ensure      => present,
    provider    => $::galera::params::pkg_provider,
    source      => "/tmp/${::galera::params::mysql_server_package}",
    require     => [Exec["download-wsrep"], Package[$::galera::params::mysql_client_package]],
  }
  
  exec { "download-wsrep" :
    command     => "/usr/bin/wget -P/tmp https://launchpad.net/codership-mysql/${::galera::params::mysql_version}/+download/${::galera::params::mysql_server_package}",
    creates     => "/tmp/${::galera::params::mysql_server_package}"
  }

  package { "galera" :
    ensure      => present,
    provider    => $::galera::params::pkg_provider,
    source      => "/tmp/${::galera::params::galera_package}",
    require     => [Exec["download-galera"], Package[$::galera::params::libssl_package]],
  }

  exec { "download-galera" :
    command     => "/usr/bin/wget -P/tmp https://launchpad.net/galera/2.x/23.2.1/+download/${::galera::params::galera_package}",
    creates     => "/tmp/${::galera::params::galera_package}",
  }

  file { "/etc/mysql/conf.d/wsrep.cnf" :
    ensure      => present,
    content     => template("galera/wsrep.cnf.erb"),
    require     => Package["mysql-server-wsrep", "galera"],
  }

  exec { "set-mysql-password" :
    unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
    command     => "/usr/bin/mysql -uroot -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${mysql_user}'@'%' identified by '${mysql_password}';flush privileges;\"",
    require     => Service["mysql-galera"],
    subscribe   => Service["mysql-galera"],
    refreshonly => true,
  }

}
