# Class: qpid::server
#
# This module manages the installation and config of the qpid server.
class qpid::server(
  $config_file = '/etc/qpidd.conf',
  $package_name = 'qpid-cpp-server',
  $package_ensure = present,
  $service_name = 'qpidd',
  $service_ensure = running,
  $port = '5672',
  $max_connections = '500',
  $worker_threads = '17',
  $connection_backlog = '10',
  $auth = 'no',
  $realm = 'QPID',
  $log_to_file = 'UNSET',
  $cluster_mechanism = 'ANONYMOUS'
) {

  validate_re($port, '\d+')
  validate_re($max_connections, '\d+')
  validate_re($worker_threads, '\d+')
  validate_re($connection_backlog, '\d+')
  validate_re($auth, '^(yes$|no$)')

  package { $package_name:
    ensure => $package_ensure
  }
 
  file { $config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => 644,
    content => template('qpid/qpidd.conf.erb'),
    subscribe => Package[$package_name]
  }

  if $log_to_file != 'UNSET' {
    file { $log_to_file:
      ensure  => present,
      owner => 'qpidd',
      group => 'qpidd',
      mode => 644,
      notify => Service[$service_name]
    }
  }

  service { $service_name:
    ensure => $service_ensure,
    subscribe => [Package[$package_name], File[$config_file]]
  }

}
