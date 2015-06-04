#
# == Define: percona
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
#  resolving system. If you are not sure that your DNS/NIS/whatever are
#  configured correctly, set this value to true.
#
# [*node_addresses*]
#  Array with IPs/hostnames of cluster members.
#
# [*wsrep_sst_method*]
#  (optional) The method for state snapshot transfer between nodes
#  Defaults to xtrabackup-v2
#  xtrabackup, xtrabackup-v2, mysqldump are supported

class percona (
  $cluster_name         = 'openstack',
  $primary_controller   = false,
  $node_address         = $ipaddress_eth0,
  $setup_multiple_gcomm = true,
  $skip_name_resolve    = false,
  $node_addresses       = [$ipaddress_eth0],
  $use_syslog           = false,
  $gcomm_port           = '4567',
  $status_check         = true,
  $wsrep_sst_method     = 'xtrabackup-v2',
  $wsrep_sst_password   = undef,
  $use_percona_packages = true,
  ) {
  include percona::params

  validate_array($node_addresses)

  anchor {'database-cluster': }

  $mysql_user     = $::percona::params::mysql_user
  $mysql_password = $wsrep_sst_password ? {
    undef   => $::percona::params::mysql_password,
    default => $wsrep_sst_password
  }
  $libgalera_prefix        = $::percona::params::libgalera_prefix
  $mysql_buffer_pool_size  = $::percona::params::mysql_buffer_pool_size
  $mysql_log_file_size     = $::percona::params::mysql_log_file_size
  $max_connections         = $::percona::params::max_connections
  $table_open_cache        = $::percona::params::table_open_cache
  $key_buffer_size         = $::percona::params::key_buffer_size
  $myisam_sort_buffer_size = $::percona::params::myisam_sort_buffer_size
  $wait_timeout            = $::percona::params::wait_timeout
  $open_files_limit        = $::percona::params::open_files_limit
  $datadir                 = $::mysql::params::datadir
  $service_name            = $::percona::params::service_name
  $innodb_flush_method     = $::percona::params::innodb_flush_method

  file { '/etc/my.cnf':
    ensure  => present,
    content => template('percona/my.cnf.erb'),
  }

  if $::operatingsystem == 'Ubuntu' {
    #Disable service autostart
    file { '/usr/sbin/policy-rc.d':
      ensure  => present,
      content => inline_template("#!/bin/sh\nexit 101\n"),
      mode    => '0755',
      before  => Package['MySQL-server']
    }

    #FIXME:
    #Remove this after https://bugs.launchpad.net/bugs/1461304 will be fixed
    file {'/etc/apt/apt.conf.d/99tmp':
      ensure  => present,
      content => inline_template("Dpkg::Options {\n\t\"--force-overwrite\";\n}"),
      before  => Package['MySQL-server']
    }
  }

  package { 'mysql-client':
    ensure => present,
    name   => $::percona::params::mysql_client_name,
    before => Package['MySQL-server']
  }

  file { ['/etc/mysql',
          '/etc/mysql/conf.d']:
    ensure => directory,
    before => Package['MySQL-server']
  }

  if $::percona::params::mysql_version {
    $wsrep_version = $::percona::params::mysql_version
  } else {
    $wsrep_version = 'installed'
  }

  if $wsrep_sst_method in [ 'xtrabackup', 'xtrabackup-v2' ] {
    firewall {'101 xtrabackup':
      port   => 4444,
      proto  => 'tcp',
      action => 'accept',
      before => Package['MySQL-server'],
    }
    package { 'percona-xtrabackup':
      ensure => present,
      before => Package['MySQL-server'],
    }
    $wsrep_sst_auth = true
  }
  elsif $wsrep_sst_method == 'mysqldump' {
    $wsrep_sst_auth = true
  }
  else {
    $wsrep_sst_auth = undef
    warning("Unrecognized wsrep_sst method: ${wsrep_sst_auth}")
  }

  package { 'galera':
    ensure => present,
    name   => $::percona::params::libgalera_package,
    before => Package['MySQL-server'],
  }

  package { 'MySQL-server':
    ensure => $wsrep_version,
    name   => $::percona::params::mysql_server_name,
  }

  file { '/etc/init.d/mysql':
    ensure  => present,
    mode    => '0644',
    require => Package['MySQL-server'],
  }

  if $primary_controller {
    $percona_socket = $::percona::params::percona_socket

    # TODO(bogdando) move to extras as a wrapper class
    cs_resource { "p_${service_name}":
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => 'mysql-wss',
      complex_type    => 'clone',
      parameters      => {
        'test_user'   => $mysql_user,
        'test_passwd' => $mysql_password,
        'socket'      => $percona_socket,
      },
      operations      => {
        'monitor' => {
          'interval' => '60',
          'timeout'  => '55'
        },
        'start'   => {
          'timeout' => '300'
        },
        'stop'    => {
          'timeout' => '120'
        },
      },
    }
    Anchor['database-cluster'] ->
      Cs_resource["p_${service_name}"] ->
        Service['mysql'] ->
          Exec['wait-for-synced-state']
  } else {
    Anchor['database-cluster'] ->
      Service['mysql']
  }

  tweaks::ubuntu_service_override { 'mysql':
    package_name => 'MySQL-server',
  }

  service { 'mysql':
    ensure   => 'running',
    name     => "p_${service_name}",
    enable   => true,
    provider => 'pacemaker',
  }

  Service['mysql'] -> Anchor['database-cluster-done']
  # lint:ignore:quoted_booleans
  if $::galera_gcomm_empty == 'true' {
    # lint:endignore
    #FIXME(bogdando): dirtyhack to pervert imperative puppet nature.
    if $::mysql_log_file_size_real != $mysql_log_file_size {
      # delete MySQL ib_logfiles, if log file size does not match the one
      # from params
      exec { 'delete_logfiles':
        command => "rm -f ${datadir}/ib_logfile* || true",
        path    => [ '/sbin/', '/usr/sbin/', '/usr/bin/' ,'/bin/' ],
        before  => File['/etc/mysql/conf.d/wsrep.cnf'],
      }
      # use predefined value for log file size
      $innodb_log_file_size_real = $mysql_log_file_size
    } else {
      # evaluate existing log file size and use it as a value
      $innodb_log_file_size_real = $::mysql_log_file_size_real
    }
  }

  file { '/etc/mysql/conf.d/wsrep.cnf':
    ensure  => present,
    content => template('percona/wsrep.cnf.erb'),
    require => [File['/etc/mysql/conf.d'], File['/etc/mysql']],
  }

  File['/etc/mysql/conf.d/wsrep.cnf'] -> Package['MySQL-server']
  File['/etc/mysql/conf.d/wsrep.cnf'] ~> Service['mysql']

  #This file contains initial sql requests for creating replication users.
  file { '/tmp/wsrep-init-file':
    ensure  => present,
    content => template('percona/wsrep-init-file.erb'),
  }

  $user_password_string="-u${mysql_user} -p${mysql_password}"
  exec { 'wait-initial-sync':
    command     => "/usr/bin/mysql ${user_password_string} -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q -e Synced -e Initialized && sleep 10",
    try_sleep   => 5,
    tries       => 60,
    refreshonly => true,
  }

  exec { 'rm-init-file':
    command => '/bin/rm /tmp/wsrep-init-file',
  }

  exec { 'wait-for-synced-state':
    command   => "/usr/bin/mysql ${user_password_string} -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q Synced && sleep 10",
    try_sleep => 5,
    tries     => 60,
  }

  if $::operatingsystem == 'Ubuntu' {
    #Clean tmp files:
    exec { 'rm-policy-rc.d':
      command => '/bin/rm /usr/sbin/policy-rc.d',
    }
    exec {'rm-99tmp':
      command => '/bin/rm /etc/apt/apt.conf.d/99tmp',
    }
    Exec['wait-for-synced-state'] ->
      Exec['rm-policy-rc.d']
    Exec['wait-for-synced-state'] ->
      Exec['rm-99tmp']

  }

  File['/tmp/wsrep-init-file'] ->
    Service['mysql'] ->
      Exec['wait-initial-sync'] ->
        Exec['wait-for-synced-state'] ->
          Exec ['rm-init-file']
  Package['MySQL-server'] ~> Exec['wait-initial-sync']

  anchor {'database-cluster-done': }


}
