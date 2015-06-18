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
#  [*command_options*]
#    command options to add to the cronjob
#    (eg. point to config file, or redirect output)
#    (optional) Defaults to ''.
#
class glance::cache::pruner (
  $minute           = '*/30',
  $hour             = '*',
  $monthday         = '*',
  $month            = '*',
  $weekday          = '*',
  $command_options  = '',
) {

  include glance::params

  cron { 'glance-cache-pruner':
    command     => "${glance::params::cache_pruner_command} ${command_options}",
    environment => 'PATH=/bin:/usr/bin:/usr/sbin',
    user        => 'glance',
    minute      => $minute,
    hour        => $hour,
    monthday    => $monthday,
    month       => $month,
    weekday     => $weekday,
    require     => Package[$::glance::params::api_package_name],

  }
}
