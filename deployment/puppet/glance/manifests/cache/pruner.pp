# == Class: glance::cache::pruner
#
# Installs a cron job to run glance-cache-pruner.
#
# === Parameters
#
#  [*minute*]
#    (optional) Defaults to '*/30'.
#
#  [*hour*]
#    (optional) Defaults to '*'.
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
class glance::cache::pruner (
  $minute   = '*/30',
  $hour     = '*',
  $monthday = '*',
  $month    = '*',
  $weekday  = '*',
) {

  include glance::params

  cron { 'glance-cache-pruner':
    command     => $glance::params::cache_pruner_command,
    environment => 'PATH=/bin:/usr/bin:/usr/sbin',
    user        => 'glance',
    minute      => $minute,
    hour        => $hour,
    monthday    => $monthday,
    month       => $month,
    weekday     => $weekday
  }
}
