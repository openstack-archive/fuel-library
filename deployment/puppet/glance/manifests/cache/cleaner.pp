# == Class: glance::cache::cleaner
#
# Installs a cron job to run glance-cache-cleaner.
#
# === Parameters
#
#  [*minute*]
#    (optional) Defaults to '1'.
#
#  [*hour*]
#    (optional) Defaults to '0'.
#
#  [*monthday*]
#    (optional) Defaults to '*'.
#
#  [*month*]
#    (optional) Defaults to '*'.
#
#  [*weekday*]
#    (optional) Defaults to '*'.
#
class glance::cache::cleaner (
  $minute   = 1,
  $hour     = 0,
  $monthday = '*',
  $month    = '*',
  $weekday  = '*',
) {

  include glance::params

  cron { 'glance-cache-cleaner':
    command     => $glance::params::cache_cleaner_command,
    environment => 'PATH=/bin:/usr/bin:/usr/sbin',
    user        => 'glance',
    minute      => $minute,
    hour        => $hour,
    monthday    => $monthday,
    month       => $month,
    weekday     => $weekday
  }
}
