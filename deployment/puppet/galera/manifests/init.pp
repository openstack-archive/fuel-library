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

  $mysql_user     = "wsrep_sst"
  $mysql_password = "password"

  service { "mysql-galera" :
    name        => "mysql",
    ensure      => "running",
    require     => [Package["mysql-server-wsrep", "galera"]],
    notify      => Exec["set-mysql-password"],
    hasrestart  => true,
    # hasstatus   => true, // http://projects.puppetlabs.com/issues/5610
  }

  package { ["mysql-client", "libssl0.9.8", "libaio1"] :
    ensure      => present,
  }

  package { ["mysql-server-5.5", "mysql-server-core-5.5"] :
    ensure 		=> purged,
  }

  package { "mysql-server-wsrep" :
    ensure      => present,
    provider    => "dpkg",
    source      => "/tmp/mysql-server-wsrep.deb",
    require     => [Package["mysql-server-5.5"], Package["mysql-server-core-5.5"], Package["libaio1"], File["/tmp/mysql-server-wsrep.deb"], Package["mysql-client"]],
  }

  file { "/tmp/mysql-server-wsrep.deb" :
    source => "puppet:///modules/galera/mysql-server-wsrep-5.5.23-23.6-amd64.deb"
  }

  package { "galera" :
    ensure      => present,
    provider    => "dpkg",
    source      => "/tmp/galera.deb",
    require     => [File["/tmp/galera.deb"], Package["libssl0.9.8"]],
  }

  file { "/tmp/galera.deb" :
    source => "puppet:///modules/galera/galera-23.2.1-amd64.deb"
  }

  file { "/etc/mysql/conf.d/wsrep.cnf" :
    ensure      => present,
    content     => template("galera/wsrep.cnf.erb"),
    require     => Package["mysql-server-wsrep", "galera"],
    notify      => Exec["restart-mysql-galera"],
  }

  exec { "restart-mysql-galera": # Can't just notify the service as this would introduce a dependency loop.
    command => "sudo service mysql restart; sleep 10s", # sleep to make initial state transfer possible before service is restarted again by mysql::config [BUG; TODO create better fix]
    path => ["/usr/bin", "/usr/sbin", "/sbin", "/bin"],
    refreshonly => true,
  }

  exec { "set-mysql-password" :
    unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
    command     => "/usr/bin/mysql -uroot -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${mysql_user}'@'%' identified by '${mysql_password}';flush privileges;\"",
    require     => Service["mysql-galera"],
    notify      => File["/etc/mysql/conf.d/wsrep.cnf"],
    refreshonly => true,
  }

}
