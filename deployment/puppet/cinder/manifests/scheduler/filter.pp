# == Class: cinder:scheduler::filter
#
# This class is aim to configure cinder.scheduler filter
#
# === Parameters:
#
# [*scheduler_default_filters*]
#   A comma separated list of filters to be used by default
#   Defaults to false

class cinder::scheduler::filter (
  $scheduler_default_filters = false,
) {

  if ($scheduler_default_filters) {
    cinder_config { 'DEFAULT/scheduler_default_filters': value  => join($scheduler_default_filters,',')
    }
  } else {
    cinder_config { 'DEFAULT/scheduler_default_filters': ensure => absent
    }
  }

}
