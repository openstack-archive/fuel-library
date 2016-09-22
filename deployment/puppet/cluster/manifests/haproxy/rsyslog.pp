# == Class: cluster::haproxy::rsyslog
#
# Configure rsyslog for corosync/pacemaker managed HAProxy
#
# === Parameters
#
# [*log_file*]
# Log file location for haproxy. Defaults to '/var/log/haproxy.log'
#
class cluster::haproxy::rsyslog (
  $log_file = '/var/log/haproxy.log',
) {
  include ::rsyslog::params

  file { '/etc/rsyslog.d/49-haproxy.conf':
    ensure  => present,
    content => template("${module_name}/haproxy.conf.erb"),
    notify  => Service[$::rsyslog::params::service_name],
  }

  if !defined(Service[$::rsyslog::params::service_name]) {
    service { $::rsyslog::params::service_name:
      ensure => 'running',
      enable => true,
    }
  }
}
