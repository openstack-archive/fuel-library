# == Class: nova:scheduler::filter
#
# This class is aim to configure nova.scheduler filter
#
# === Parameters:
#
# ==== Options defined in nova.scheduler.driver
# scheduler_host_manager: The scheduler host manager class to use
# scheduler_max_attempts: Maximum number of attempts to schedule an instance

# ==== Options defined in nova.scheduler.filter_scheduler
# scheduler_host_subset_size: defines the subset size that a host is chosen from

# ==== Options defined in nova.scheduler.filters.core_filter
# cpu_allocation_ratio:   Virtual CPU to Physical CPU allocation ratio (float)

# ==== Options defined in nova.scheduler.filters.disk_filter
# disk_allocation_ratio:  Virtual disk to physical disk allocation ratio (float)

# ==== Options defined in nova.scheduler.filters.io_ops_filter
# max_io_ops_per_host:    Ignore hosts that have too many builds/resizes
#                         /snaps/migrations (Int)

# ==== Options defined in nova.scheduler.filters.isolated_hosts_filter
# isolated_images: Images to run on isolated host (list value)
# isolated_hosts:  Host reserved for specific images (list value)

# ==== Options defined in nova.scheduler.filters.num_instances_filter
# max_instances_per_host: Ignore hosts that have too many instances (Int)

# ==== Options defined in nova.scheduler.filters.ram_filter
# ram_allocation_ratio:   Virtual ram to physical ram allocation ratio (Int)

# ==== Options defined in nova.scheduler.host_manager
# scheduler_available_filters
# scheduler_default_filters
# scheduler_weight_classes
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
