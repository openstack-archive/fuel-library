# == Class: rsyslog::config
#
# Full description of class role here.
#
# === Parameters
#
# === Variables
#
# === Examples
#
#  class { 'rsyslog::config': }
#
class rsyslog::config {
  file { $rsyslog::rsyslog_d:
    ensure  => directory,
    owner   => 'root',
    group   => $rsyslog::run_group,
    purge   => $rsyslog::purge_rsyslog_d,
    recurse => true,
    force   => true,
    require => Class['rsyslog::install'],
  }

  file { $rsyslog::rsyslog_conf:
    ensure  => file,
    owner   => 'root',
    group   => $rsyslog::run_group,
    content => template("${module_name}/rsyslog.conf.erb"),
    require => Class['rsyslog::install'],
    notify  => Class['rsyslog::service'],
  }

  file { $rsyslog::rsyslog_default:
    ensure  => file,
    owner   => 'root',
    group   => $rsyslog::run_group,
    source  => "puppet:///modules/rsyslog/${rsyslog::rsyslog_default_file}",
    require => Class['rsyslog::install'],
    notify  => Class['rsyslog::service'],
  }

  file { $rsyslog::spool_dir:
    ensure  => directory,
    owner   => 'root',
    group   => $rsyslog::run_group,
    seltype => 'syslogd_var_lib_t',
    require => Class['rsyslog::install'],
    notify  => Class['rsyslog::service'],
  }

}
