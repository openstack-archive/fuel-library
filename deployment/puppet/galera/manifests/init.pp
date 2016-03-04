#    Copyright 2013 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
#
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
# [*gcache_factor*]
#   The gcache factor is based on cluster node's count.
#   Used in config template for `wsrep_provider_option`.
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
#
# [*use_percona*]
#  Boolean. Set this value to true if you want to use percona instead of
#  the mysql packages.
#
# [*use_percona_packages*]
#  Boolean. Set this value to true to use the Percona distrubuted packages.
#  This requires that these packages are available via a repository for the
#  system at install time. NOTE: use_percona must be set to true for this to
#  be used.
#
# [*binary_logs_enabled*]
#  Set this value to true for enabling MySQL binary logging.
#  Defaults to false
#
# [*binary_logs_period*]
#  (optional) Set binary logrotation period in days.
#  Defaults to 1
#
# [*binary_logs_maxsize*]
# (optional) If a write to the binary log causes the current log file
# size to exceed the value of this variable, the server rotates the
# binary logs (closes the current file and opens the next one). The
# minimum value is 4096 bytes. The maximum and default value is 512MB.
#
# [*ignore_db_dirs*]
#  (optional) array of directories to ignore in datadir.
#  Defaults to []
#

class galera (
  $cluster_name         = 'openstack',
  $primary_controller   = false,
  $node_address         = $ipaddress_eth0,
  $setup_multiple_gcomm = true,
  $skip_name_resolve    = false,
  $node_addresses       = [ $ipaddress_eth0 ],
  $gcache_factor        = 0,
  $use_syslog           = false,
  $gcomm_port           = '4567',
  $status_check         = true,
  $wsrep_sst_method     = 'xtrabackup-v2',
  $wsrep_sst_password   = undef,
  $use_percona          = false,
  $use_percona_packages = false,
  $binary_logs_enabled  = false,
  $binary_logs_period   = 1,
  $binary_logs_maxsize  = '512M',
  $ignore_db_dirs       = [],
  ) {

  include galera::params

  validate_array($node_addresses)
  validate_bool($use_percona)
  validate_bool($use_percona_packages)

  anchor {'database-cluster': }

  $mysql_user              = $::galera::params::mysql_user
  $mysql_password          = $wsrep_sst_password ? {
    undef   => $::galera::params::mysql_password,
    default => $wsrep_sst_password
  }
  $libgalera_prefix        = $::galera::params::libgalera_prefix
  $mysql_buffer_pool_size  = $::galera::params::mysql_buffer_pool_size
  $mysql_log_file_size     = $::galera::params::mysql_log_file_size
  $max_connections         = $::galera::params::max_connections
  $table_open_cache        = $::galera::params::table_open_cache
  $key_buffer_size         = $::galera::params::key_buffer_size
  $myisam_sort_buffer_size = $::galera::params::myisam_sort_buffer_size
  $wait_timeout            = $::galera::params::wait_timeout
  $open_files_limit        = $::galera::params::open_files_limit
  $datadir                 = $::mysql::params::datadir
  $service_name            = $::galera::params::service_name
  $innodb_flush_method     = $::galera::params::innodb_flush_method

  package { ['wget',
              'perl']:
    ensure => present,
    before => Package['MySQL-server'],
  }

  file { '/etc/my.cnf':
    ensure  => present,
    content => template('galera/my.cnf.erb'),
  }

  if ($use_percona and $::operatingsystem == 'Ubuntu') {
    # Disable service autostart
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
    name   => $::galera::params::mysql_client_name,
    before => Package['MySQL-server']
  }

  file { ['/etc/mysql',
          '/etc/mysql/conf.d']:
    ensure => directory,
    before => Package['MySQL-server']
  }

  if !($use_percona) {
    package { $::galera::params::libaio_package:
      ensure => present,
      before => Package['galera', 'MySQL-server']
    }
  }

  package { 'galera':
    ensure => present,
    name   => $::galera::params::libgalera_package,
    before => Package['MySQL-server']
  }

  if $::galera::params::mysql_version {
    $wsrep_version = $::galera::params::mysql_version
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

  package { 'MySQL-server':
    ensure   => $wsrep_version,
    name     => $::galera::params::mysql_server_name,
    provider => $::galera::params::pkg_provider,
  }

  file { '/etc/init.d/mysql':
    ensure  => present,
    mode    => '0644',
    require => Package['MySQL-server'],
  }


  if $primary_controller {
    $galera_socket = $::galera::params::database_socket

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
        'socket'      => $galera_socket,
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

  #FIXME(bogdando): dirtyhack to pervert imperative puppet nature.
  if $::mysql_log_file_size_real != $mysql_log_file_size {
    if str2bool($::galera_gcomm_empty) {
      # delete MySQL ib_logfiles, if log file size does not match the one
      # from params
      exec { 'delete_logfiles':
        command => "rm -f ${datadir}/ib_logfile* || true",
        path    => [ '/sbin/', '/usr/sbin/', '/usr/bin/' ,'/bin/' ],
        before  => File['/etc/mysql/conf.d/wsrep.cnf'],
      }
    }
    # use predefined value for log file size
    $innodb_log_file_size_real = $mysql_log_file_size
  } else {
    # evaluate existing log file size and use it as a value
    $innodb_log_file_size_real = $::mysql_log_file_size_real
  }
  file { '/etc/mysql/conf.d/wsrep.cnf':
    ensure  => present,
    content => template('galera/wsrep.cnf.erb'),
    require => [File['/etc/mysql/conf.d'], File['/etc/mysql']],
  }

  File['/etc/mysql/conf.d/wsrep.cnf'] -> Package['MySQL-server']
  File['/etc/mysql/conf.d/wsrep.cnf'] ~> Service['mysql']
# This file contains initial sql requests for creating replication users.

  file { '/tmp/wsrep-init-file':
    ensure  => present,
    content => template('galera/wsrep-init-file.erb'),
  }

# This exec waits for initial sync of galera cluster after mysql replication
# user creation.

  $user_password_string="-u${mysql_user} -p${mysql_password}"
  exec { 'wait-initial-sync':
    command     => "/usr/bin/mysql ${user_password_string} -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q -e Synced -e Initialized && sleep 10",
    try_sleep   => 10,
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

  if ($use_percona and $::operatingsystem == 'Ubuntu') {
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
