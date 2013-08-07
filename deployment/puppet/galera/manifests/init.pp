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

  $cib_name = "mysql"
  $res_name = "p_${cib_name}"

  $mysql_user = $::galera::params::mysql_user
  $mysql_password = $::galera::params::mysql_password
  $libgalera_prefix = $::galera::params::libgalera_prefix

  case $::osfamily {
    'RedHat' : {

      file { '/etc/init.d/mysql':
        ensure  => present,
        mode    => 644,
        require => Package['MySQL-server'],
        before  => Service["$cib_name"]
      }

      file { '/etc/my.cnf':
        ensure => present,
        content => template("galera/my.cnf.erb"),
        before => Service["$cib_name"]
      }

      package { 'MySQL-client':
        ensure => present,
        before => Package['MySQL-server']
      }

      package { 'wget':
        ensure => present,
      }

      package { 'bc':
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
        mode    => 644,
        source => 'puppet:///modules/galera/mysql.init' , 
        require => Package['MySQL-server'],
        before  => Service["$cib_name"]
      }

      file { '/etc/my.cnf':
        ensure => present,
        content => template("galera/my.cnf.erb"),
        before => Service["$cib_name"]
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

    }
  }
 cs_shadow { $res_name: cib => $cib_name }
 cs_commit { $res_name: cib => $cib_name } ~> ::Corosync::Cleanup["$res_name"]
    ::corosync::cleanup { $res_name: }
 cs_resource { "$res_name":
      ensure => present,
      cib => $cib_name,
      primitive_class => 'ocf',
      provided_by     => 'mirantis', 
      primitive_type => 'mysql',
      multistate_hash => {
        'type' => 'clone',
      },
      ms_metadata => {
        'interleave' => 'true',
      },
      operations => {
        'monitor' => {
          'interval' => '60',
          'timeout' => '30'
        },
        'start' => {
          'timeout' => '450'
        },
        'stop' => {
          'timeout' => '150'
        },
     },
   }

  Package['MySQL-server'] -> Cs_resource['p_mysql']
  service { "mysql":
    name       => "p_mysql",
    enable     => true,
    ensure     => "running",
    require    => [Package["MySQL-server", "galera"]],
    provider   => "pacemaker",
  }
  Package['pacemaker'] -> File['mysql-wss']
   Cs_resource["$res_name"] ->
      Cs_commit["$res_name"] ->
          Service["$cib_name"]

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
    File["/etc/mysql/conf.d/wsrep.cnf"] -> Package['MySQL-server']
  }

#TODO: find another way of mysql initial replication users creation


# This file contains initial sql requests for creating replication users.

  file { "/tmp/wsrep-init-file":
    ensure  => present,
    content => template("galera/wsrep-init-file.erb"),
  }

# This exec waits for initial sync of galera cluster after mysql replication user creation.

  exec { "wait-initial-sync":
    logoutput   => true,
    command     => "/usr/bin/mysql -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q -e Synced -e Initialized && sleep 10",
    try_sleep   => 5,
    tries       => 60,
    refreshonly => true,
  }

  exec { "rm-init-file":
    command => "/bin/rm /tmp/wsrep-init-file",
  }

  exec { "wait-for-synced-state":
    logoutput => true,
    command   => "/usr/bin/mysql -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q Synced && sleep 10",
    try_sleep => 5,
    tries     => 60,
  }

  exec { "raise-first-setup-flag" :
   path    => "/usr/bin:/usr/sbin:/bin:/sbin",
   command => "crm_attribute -t crm_config --name mysqlprimaryinit --update done",
   refreshonly => true,
  }



  File["/tmp/wsrep-init-file"] -> Service["$cib_name"] -> Exec["wait-initial-sync"] -> Exec ["wait-for-synced-state"] -> Exec ["rm-init-file"]
  Package["MySQL-server"] ~> Exec ["wait-initial-sync"]

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
      command   => 'echo Primary-controller completed',
      require    => Service["$cib_name"],
      before     => Exec ["wait-for-synced-state"],
      notify     => Exec ["raise-first-setup-flag"],
    }
  }
}
