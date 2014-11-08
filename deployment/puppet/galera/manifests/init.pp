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
# [*wsrep_sst_method*]
#  (optional) The method for state snapshot transfer between nodes
#  Defaults to xtrabackup-v2
#  xtrabackup, xtrabackup-v2, mysqldump are supported

class galera (
  $cluster_name         = 'openstack',
  $primary_controller   = false,
  $node_address         = $ipaddress_eth0,
  $setup_multiple_gcomm = true,
  $skip_name_resolve    = false,
  $node_addresses       = $ipaddress_eth0,
  $use_syslog           = false,
  $gcomm_port           = '4567',
  $status_check         = true,
  $wsrep_sst_method     = 'xtrabackup-v2'
  ) {
  include galera::params

  anchor {'galera': }

  $mysql_user = $::galera::params::mysql_user
  $mysql_password = $::galera::params::mysql_password
  $libgalera_prefix = $::galera::params::libgalera_prefix
  $mysql_buffer_pool_size = $::galera::params::mysql_buffer_pool_size
  $mysql_log_file_size = $::galera::params::mysql_log_file_size
  $max_connections = $::galera::params::max_connections
  $table_open_cache = $::galera::params::table_open_cache
  $key_buffer_size = $::galera::params::key_buffer_size
  $myisam_sort_buffer_size = $::galera::params::myisam_sort_buffer_size
  $wait_timeout = $::galera::params::wait_timeout
  $open_files_limit= $::galera::params::open_files_limit
  $datadir=$::mysql::params::datadir
  $service_name=$::galera::params::service_name

  package { ['wget',
              'perl']:
    ensure => present,
    before => Package['MySQL-server'],
  }

  file { '/etc/my.cnf':
    ensure  => present,
    content => template('galera/my.cnf.erb'),
    before  => File['mysql-wss-ocf']
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

  package { $::galera::params::libaio_package:
    ensure => present,
    before => Package['galera', 'MySQL-server']
  }

  package { 'galera':
    ensure => present,
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
    before  => File['mysql-wss-ocf']
  }


  if $primary_controller {
    $galera_pid = $::osfamily ? {
      'RedHat' => '/var/run/mysql/mysqld.pid',
      'Debian' => '/var/run/mysqld/mysqld.pid',
    }
    $galera_socket = $::osfamily ? {
      'RedHat' => '/var/lib/mysql/mysql.sock',
      'Debian' => '/var/run/mysqld/mysqld.sock',
    }
    cs_resource { "p_${service_name}":
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'mysql-wss',
      multistate_hash => {
        'type'        => 'clone',
      },
      parameters      => {
        'test_user'   => "${mysql_user}",
        'test_passwd' => "${mysql_password}",
        'pid'         => "${galera_pid}",
        'socket'      => "${galera_socket}",
      },
      operations      => {
        'monitor' => {
          'interval' => '120',
          'timeout'  => '115'
        },
        'start'   => {
          'timeout' => '475'
        },
        'stop'    => {
          'timeout' => '175'
        },
      },
    }
    Anchor['galera'] ->
      File['mysql-wss-ocf'] ->
        Service["${service_name}_stopped"] ->
          Cs_resource["p_${service_name}"] ->
            Service["${service_name}-service"] ->
              Exec['wait-for-synced-state']
  } else {
    Anchor['galera'] ->
      File['mysql-wss-ocf'] ->
        Service["${service_name}_stopped"] ->
          Service["${service_name}-service"]
  }

  file { 'mysql-wss-ocf':
    path   => '/usr/lib/ocf/resource.d/mirantis/mysql-wss',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/galera/ocf/mysql-wss',
  }

  File<| title == 'ocf-mirantis-path' |> -> File['mysql-wss-ocf']

  Package['MySQL-server', 'galera'] -> File['mysql-wss-ocf']

  tweaks::ubuntu_service_override { "${service_name}":
    package_name => 'MySQL-server',
  }

  service { "${service_name}_stopped":
    ensure => 'stopped',
    name   => "${service_name}",
    enable => false,
  }

  service { "${service_name}-service":
    ensure     => 'running',
    name       => "p_${service_name}",
    enable     => true,
    provider   => 'pacemaker',
  }

  Service["${service_name}-service"] -> Anchor['galera-done']

  if $::galera_gcomm_empty == 'true' {
    #FIXME(bogdando): dirtyhack to pervert imperative puppet nature.
    if $::mysql_log_file_size_real != $mysql_log_file_size {
      # delete MySQL ib_logfiles, if log file size does not match the one
      # from params
      exec { 'delete_logfiles':
        command     => "rm -f ${datadir}/ib_logfile* || true",
        path        => [ '/sbin/', '/usr/sbin/', '/usr/bin/' ,'/bin/' ],
        before      => File['/etc/mysql/conf.d/wsrep.cnf'],
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
    content => template('galera/wsrep.cnf.erb'),
    require => [File['/etc/mysql/conf.d'], File['/etc/mysql']],
  }

  File['/etc/mysql/conf.d/wsrep.cnf'] -> Package['MySQL-server']
  File['/etc/mysql/conf.d/wsrep.cnf'] ~> Service["${service_name}-service"]
# This file contains initial sql requests for creating replication users.

  file { '/tmp/wsrep-init-file':
    ensure  => present,
    content => template('galera/wsrep-init-file.erb'),
  }

# This exec waits for initial sync of galera cluster after mysql replication user creation.

  $user_password_string="-u${mysql_user} -p${mysql_password}"
  exec { 'wait-initial-sync':
    logoutput   => true,
    command     => "/usr/bin/mysql ${user_password_string} -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q -e Synced -e Initialized && sleep 10",
    try_sleep   => 5,
    tries       => 60,
    refreshonly => true,
  }

  exec { 'rm-init-file':
    command => '/bin/rm /tmp/wsrep-init-file',
  }

  exec { 'wait-for-synced-state':
    logoutput => true,
    command   => "/usr/bin/mysql ${user_password_string} -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q Synced && sleep 10",
    try_sleep => 5,
    tries     => 60,
  }

  File['/tmp/wsrep-init-file'] ->
    Service["${service_name}-service"] ->
      Exec['wait-initial-sync'] ->
        Exec['wait-for-synced-state'] ->
          Exec ['rm-init-file']
  Package['MySQL-server'] ~> Exec['wait-initial-sync']

  if $status_check {
    include galera::status
  }

  anchor {'galera-done': }
}
