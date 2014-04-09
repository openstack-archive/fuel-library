# == Class: nova:scheduler::filter
#
# This class is aim to configure nova.scheduler filter
#
# === Parameters:
#
# [*scheduler_host_manager*]
#   (optional) The scheduler host manager class to use
#   Defaults to 'nova.scheduler.host_manager.HostManager'
#
# [*scheduler_max_attempts*]
#   (optional) Maximum number of attempts to schedule an instance
#   Defaults to '3'
#
# [*scheduler_host_subset_size*]
#   (optional) defines the subset size that a host is chosen from
#   Defaults to '1'
#
# [*cpu_allocation_ratio*]
#   (optional) Virtual CPU to Physical CPU allocation ratio
#   Defaults to '16.0'
#
# [*disk_allocation_ratio*]
#   (optional) Virtual disk to physical disk allocation ratio
#   Defaults to '1.0'
#
# [*max_io_ops_per_host*]
#   (optional) Ignore hosts that have too many builds/resizes/snaps/migrations
#   Defaults to '8'
#
# [*isolated_images*]
#   (optional) Images to run on isolated host
#   Defaults to false
#
# [*isolated_hosts*]
#   (optional) Host reserved for specific images
#   Defaults to false
#
# [*max_instances_per_host*]
#   (optional) Ignore hosts that have too many instances
#   Defaults to '50'
#
# [*ram_allocation_ratio:*]
#   (optional) Virtual ram to physical ram allocation ratio
#   Defaults to '1.5'
#
# [*scheduler_available_filters*]
#   (optional) Filter classes available to the scheduler
#   Defaults to 'nova.scheduler.filters.all_filters'
#
# [*scheduler_default_filters*]
#   (optional) A comma separated list of filters to be used by default
#   Defaults to false
#
# [*scheduler_weight_classes*]
#   (optional) Which weight class names to use for weighing hosts
#   Defaults to 'nova.scheduler.weights.all_weighers'
#
class nova::scheduler::filter (
  $scheduler_host_manager       = 'nova.scheduler.host_manager.HostManager',
  $scheduler_max_attempts       = '3',
  $scheduler_host_subset_size   = '1',
  $cpu_allocation_ratio         = '16.0',
  $disk_allocation_ratio        = '1.0',
  $max_io_ops_per_host          = '8',
  $max_instances_per_host       = '50',
  $ram_allocation_ratio         = '1.5',
  $isolated_images              = false,
  $isolated_hosts               = false,
  $scheduler_available_filters  = 'nova.scheduler.filters.all_filters',
  $scheduler_default_filters    = false,
  $scheduler_weight_classes     = 'nova.scheduler.weights.all_weighers',
) {

  nova_config {
    'DEFAULT/scheduler_host_manager':       value => $scheduler_host_manager;
    'DEFAULT/scheduler_max_attempts':       value => $scheduler_max_attempts;
    'DEFAULT/scheduler_host_subset_size':   value => $scheduler_host_subset_size;
    'DEFAULT/cpu_allocation_ratio':         value => $cpu_allocation_ratio;
    'DEFAULT/disk_allocation_ratio':        value => $disk_allocation_ratio;
    'DEFAULT/max_io_ops_per_host':          value => $max_io_ops_per_host;
    'DEFAULT/max_instances_per_host':       value => $max_instances_per_host;
    'DEFAULT/ram_allocation_ratio':         value => $ram_allocation_ratio;
    'DEFAULT/scheduler_available_filters':  value => $scheduler_available_filters;
    'DEFAULT/scheduler_weight_classes':     value => $scheduler_weight_classes
  }
  if ($scheduler_default_filters)  {
    nova_config { 'DEFAULT/scheduler_default_filters':  value => join($scheduler_default_filters,',')
    }
  } else {
    nova_config  { 'DEFAULT/scheduler_default_filters': ensure => absent
    }
  }
  if ($isolated_images) {
    nova_config {
      'DEFAULT/isolated_images':    value => join($isolated_images,',')
    }
  } else {
    nova_config {
      'DEFAULT/isolated_images':   ensure => absent
    }
  }
  if ($isolated_hosts) {
    nova_config {
      'DEFAULT/isolated_hosts':    value => join($isolated_hosts,',')
    }
  }  else {
    nova_config {
      'DEFAULT/isolated_hosts':    ensure => absent
    }
  }
}
