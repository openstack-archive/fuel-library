# == Class: rsyslog::modload
#

class rsyslog::modload (
  $modload_filename = '10-modload.conf',
) {
  file { "${rsyslog::rsyslog_d}${modload_filename}":
    ensure  => file,
    owner   => 'root',
    group   => $rsyslog::run_group,
    content => template('rsyslog/modload.erb'),
    require => Class['rsyslog::install'],
    notify  => Class['rsyslog::service'],
  }
}
