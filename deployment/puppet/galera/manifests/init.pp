# == Define: galera
#
# Class for installation and configuration of galer Master/Master cluster.
#
# === Parameters
#
# [*cluster_name*]
#   Cluster name for `wsrep_cluster_name` variable.
#
# [*primary_controller*]
#   Set to true if current node is the initial master/primary
#   controller.
#
# [*node_address*]
#   Which value to use as node address for filtering in gcomm address.
#   This is done due to some bugs in galera configuration. Thus we are
#   filtering this address from `wsrep_cluster_address` to avoid these
#   problems.
#
# [*setup_multiple_gcomm*]
#   Should gcomm address contain multiple nodes or not.
#
# [*skip_name_resolve*]
#  By default, MySQL tries to do reverse name mapping IP->hostname. In this
#  case MySQL requests can be timed out by clients in case of broken name  
#  resolving system. If you are not sure that your DNS/NIS/whatever are configured
#  correctly, set this value to true.
#
# [*node_addresses*]
#  Array with IPs/hostnames of cluster members.
#
# === Authors
#
# Mirantis Inc. <product@mirantis.com>
#
# === Copyright
#
# FIXME: Insert copyrights and licenses
#


class galera (
  $cluster_name,
  $primary_controller   = false,
  $node_address         = $ipaddress_eth0,
  $setup_multiple_gcomm = true,
  $skip_name_resolve    = false,
  $node_addresses       = [$ipaddress_eth0],
  $use_syslog           = false,
  ) {
  include galera::params

  $mysql_user = $::galera::params::mysql_user
  $mysql_password = $::galera::params::mysql_password
  $libgalera_prefix = $::galera::params::libgalera_prefix

  case $::osfamily {
    'RedHat' : {

      file { '/etc/init.d/mysql':
        ensure  => present,
        mode    => 755,
        require => Package['MySQL-server'],
        before  => Service['mysql-galera']
      }

      file { '/etc/my.cnf':
        ensure => present,
        content => template("galera/my.cnf.erb"),
        before => Service['mysql-galera']
      }

      package { 'MySQL-client':
        ensure => present,
        before => Package['MySQL-server']
      }

      package { 'wget':
        ensure => present,
      }

      package { 'perl':
        ensure => present,
        before => Package['MySQL-client']
      }
    }
    'Debian' : {

      file { '/etc/init.d/mysql':
        ensure  => present,
        mode    => 755,
        source => 'puppet:///modules/galera/mysql.init' , 
        require => Package['MySQL-server'],
        before  => Service['mysql-galera']
      }

      file { '/etc/my.cnf':
        ensure => present,
        content => template("galera/my.cnf.erb"),
        before => Service['mysql-galera']
      }

      package { 'wget':
        ensure => present,
      }

      package { 'perl':
        ensure => present,
        before => Package['mysql-client']
      }

      package { 'mysql-client':
        ensure => present,
        before => Package['MySQL-server']
      }

      package { 'mysql-common':
        ensure => present,
        before => Package['MySQL-server']
      }

      package { 'libc6':
        ensure => latest,
        before => Package['MySQL-server']
      }
    }
  }

  service { "mysql-galera":
    name       => "mysql",
    enable     => true,
    ensure     => "running",
    require    => [Package["MySQL-server", "galera"]],
    hasrestart => true,
    hasstatus  => true,
  }

  package { [$::galera::params::libssl_package, $::galera::params::libaio_package]:
    ensure => present,
    before => Package["galera", "MySQL-server"]
  }

  if $::galera::params::mysql_version {
   $wsrep_version = $::galera::params::mysql_version 
  }
  else
  {
   $wsrep_version = 'latest'
  }
  package { "MySQL-server":
    ensure   => $wsrep_version,
    name     => $::galera::params::mysql_server_name,
    provider => $::galera::params::pkg_provider,
    require  => Package['galera']
  }


  package { "galera":
    ensure   => $::galera::params::galera_version,
    provider => $::galera::params::pkg_provider,
  }

  # Uncomment the following Exec and sequence arrow to obtain full MySQL server installation log
  #  ->
  #  exec { "debug -mysql-server-installation" :
  #    command     => "/usr/bin/yum -d 10 -e 10 -y install MySQL-server 2>&1 | tee mysql_install.log",
  #    before => Package["MySQL-server"],
  #    logoutput => true,
  #  }

  file { ["/etc/mysql", "/etc/mysql/conf.d"]: ensure => directory, }

  if $::galera_gcomm_empty == "true" {
    file { "/etc/mysql/conf.d/wsrep.cnf":
      ensure  => present,
      content => template("galera/wsrep.cnf.erb"),
      require => [File["/etc/mysql/conf.d"], File["/etc/mysql"]],
    }
    File["/etc/mysql/conf.d/wsrep.cnf"] -> Exec['set-mysql-password']
    File["/etc/mysql/conf.d/wsrep.cnf"] ~> Exec['set-mysql-password']
    File["/etc/mysql/conf.d/wsrep.cnf"] -> Service['mysql-galera']
    File["/etc/mysql/conf.d/wsrep.cnf"] ~> Service['mysql-galera']
    File["/etc/mysql/conf.d/wsrep.cnf"] -> Package['MySQL-server']
  }

#TODO: find another way of mysql initial replication users creation


# This file contains initial sql requests for creating replication users.

  file { "/tmp/wsrep-init-file":
    ensure  => present,
    content => template("galera/wsrep-init-file.erb"),
  }

# This exec calls mysqld_safe with aforementioned file as --init-file argument, thus creating replication user.
  exec { "set-mysql-password":
    unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
    command     => "/usr/bin/mysqld_safe --init-file=/tmp/wsrep-init-file --port=3307 &",
    refreshonly => true,
  }

# This exec waits for initial sync of galera cluster after mysql replication user creation.

  exec { "wait-initial-sync":
    logoutput   => true,
    command     => "/usr/bin/mysql -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q -e Synced -e Initialized && sleep 10",
    try_sleep   => 5,
    tries       => 60,
    refreshonly => true,
  }

# This exec kills initialized mysql to allow its management with generic service providers (init/upstart/pacemaker/etc.)

  exec { "kill-initial-mysql":
    path        => "/usr/bin:/usr/sbin:/bin:/sbin",
    command     => "killall -w mysqld && ( killall -w -9 mysqld_safe || : ) && sleep 10",
    #      onlyif    => "pidof mysqld",
    try_sleep   => 5,
    tries       => 6,
    refreshonly => true,
  }

  exec { "wait-for-synced-state":
    logoutput => true,
    command   => "/usr/bin/mysql -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q Synced && sleep 10",
    try_sleep => 5,
    tries     => 60,
  }
  
  Package["MySQL-server"] -> Exec["set-mysql-password"] 
  File['/tmp/wsrep-init-file'] -> Exec["set-mysql-password"] -> Exec["wait-initial-sync"] 
  -> Exec["kill-initial-mysql"] -> Service["mysql-galera"] -> Exec ["wait-for-synced-state"]
  
  Package["MySQL-server"] ~> Exec["set-mysql-password"] ~> Exec ["wait-initial-sync"] ~> Exec["kill-initial-mysql"]

  exec { "raise-first-setup-flag" :
   path    => "/usr/bin:/usr/sbin:/bin:/sbin",
   command => "crm_attribute -t crm_config --name mysqlprimaryinit --update done",
   refreshonly => true,
  }

# FIXME: This class is deprecated and should be removed in future releases.
 
  class { 'galera::galera_master_final_config':
    require        => Exec["wait-for-haproxy-mysql-backend"],
    primary_controller => $primary_controller,
    node_addresses => $node_addresses,
    node_address   => $node_address,
  }
  
  if $primary_controller {
    exec { "start-new-galera-cluster":
      path   => "/usr/bin:/usr/sbin:/bin:/sbin",
      logoutput => true,
      command   => '/etc/init.d/mysql stop; sleep 10; killall -w mysqld && ( killall -w -9 mysqld_safe || : ) && sleep 10; /etc/init.d/mysql start --wsrep-cluster-address=gcomm:// &',
      onlyif    => "[ -f /var/lib/mysql/grastate.dat ] && (cat /var/lib/mysql/grastate.dat | awk '\$1 == \"uuid:\" {print \$2}' | awk '{if (\$0 == \"00000000-0000-0000-0000-000000000000\") exit 0; else exit 1}')",
      require    => Service["mysql-galera"],
      before     => Exec ["wait-for-synced-state"],
      notify     => Exec ["raise-first-setup-flag"], 
    }
  }
}
