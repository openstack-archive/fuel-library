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
#  [*command_options*]
#    command options to add to the cronjob
#    (eg. point to config file, or redirect output)
#    (optional) Defaults to ''.
#
class glance::cache::cleaner (
  $minute           = 1,
  $hour             = 0,
  $monthday         = '*',
  $month            = '*',
  $weekday          = '*',
  $command_options  = '',
) {

  include glance::params

  cron { 'glance-cache-cleaner':
    command     => "${glance::params::cache_cleaner_command} ${command_options}",
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
